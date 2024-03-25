@if (@Language == @Batch) @then /* JScript conditional compilation block protecting the batch section */
  @cscript //nologo //E:JScript "%~f0" %* & exit /b &:# Batch command that invokes JScript and exits
@end /* End of the JScript conditional compilation block protecting the batch section */
/*****************************************************************************\
*                                                                             *
*   File name       WhereAmI.bat / whereami.js                                *
*                                                                             *
*   Description     Get the system location based on its IP address           *
*                                                                             *
*   Notes           Uses the APIs on https://freegeoip.app/                   *
*                                                                             *
*                   A dual Batch+Javascript script, that should work in all   *
*                   versions of Windows, from XP to 10.                       *
*                                                                             *
*                   On Windows XP, @_jscript_version = 5.6                    *
*                   On Windows 10, @_jscript_version = 5.8                    *
*                   Both are roughly equivalent to JavaScript 1.5.            *
*                   https://technet.microsoft.com/en-us/library/ee156607.aspx *
*                                                                             *
*                   Microsoft JScript Features:                               *
*                   https://msdn.microsoft.com/en-us/library/4tc5a343.aspx    *
*                   The WScript object:                                       *
*		    https://docs.microsoft.com/en-us/previous-versions/at5ydy31(v%3dvs.80)
*		    https://docs.microsoft.com/en-us/previous-versions/tn-archive/ee156585(v=technet.10)
*                   Old MS JavaScript version information:                    *
*                   https://docs.microsoft.com/en-us/scripting/javascript/reference/javascript-version-information
*                   Modern JavaScript doc. Unfortunately, the cscript is older*
*                   https://docs.microsoft.com/en-us/scripting/javascript/javascript-language-reference
*                                                                             *
*   Authors:	    JFL jf.larvoire@free.fr				      *
*                                                                             *
*   History                                                                   *
*    2019-11-13 JFL Created this script.				      *
*    2019-11-14 JFL Added the optional SERVER|IP argument. 		      *
*    2019-11-16 JFL Added the DB of time zone names, and set TZABBR, DSTZABBR.*
*    2019-11-17 JFL Added options -s & -u to write respectively a system      *
*		    configuration file, and a user configuration file.        *
*    2019-11-18 JFL Avoid using the eval function.			      *
*                   Added option -X | --noexec for a no-execute mode.         *
*                   Fix querying remote servers locations.                    *
*    2023-11-22 JFL Corrected a comment.				      *
*    2024-03-24 JFL Added lots of debug statements.			      *
*                   The freegeoip.app API URL changed to api.ipbase.com/v1.   *
*                   Its xml API is now obsolete. Use the json API by default. *
*    2024-03-25 JFL Indent the debug output to improve readability.	      *
*                   Fixed the -j and -x dump option.			      *
*                                                                             *
\*****************************************************************************/

var VERSION = "2024-03-25" // Version string displayed by the -V | --version option

// Many functions in this module use these options by default:
defaultOptions = {verbose:false, debug:0};

// Private class used to abort execution with an error message
function FatalError(message) {
  var err = new Error(message || "");
  err.name = "FatalError";
  return err;
}
// Usage example: throw new FatalError("This is impossible");
// When used as a standalone program, this error message is written to stderr:
// Error: This is impossible

// Trim any character in chars from both ends of str
function Trim(str, chars) {
  var start = 0, end = str.length;
  while ((start < end) && (chars.indexOf(str.charAt(start)) >= 0)) ++start;
  while ((end > start) && (chars.indexOf(str.charAt(end-1)) >= 0)) --end;
  return ((end - start) < str.length) ? str.substring(start, end) : str;
}

// Indent a multi-line string by 2 spaces
function Indent(str) {
  if ((!str) || !str.length) return str;
  var len = str.length;
  var last = str.charAt[len-1]; // Avoid indenting the last line if last == '\n'
  return "  " + str.substr(0, len-1).replace(/\n/gm, "\n  ") + last;
}

/*---------------------------------------------------------------------------*/
/* Database of timezone names */
/* Adapted from Boost date_time_zonespec.csv at
   https://github.com/boostorg/date_time/blob/master/data/date_time_zonespec.csv
   See Boost copyright at https://github.com/boostorg/date_time/blob/develop/LICENSE */
var tzNamesDB = [
  /* Full name, Abbreviation, DST Abbreviation */
  ["Africa/Abidjan", "GMT", null],
  ["Africa/Accra", "GMT", null],
  ["Africa/Addis_Ababa", "EAT", null],
  ["Africa/Algiers", "CET", null],
  ["Africa/Asmara", "EAT", null],
  ["Africa/Asmera", "EAT", null],
  ["Africa/Bamako", "GMT", null],
  ["Africa/Bangui", "WAT", null],
  ["Africa/Banjul", "GMT", null],
  ["Africa/Bissau", "GMT", null],
  ["Africa/Blantyre", "CAT", null],
  ["Africa/Brazzaville", "WAT", null],
  ["Africa/Bujumbura", "CAT", null],
  ["Africa/Cairo", "EET", null],
  ["Africa/Casablanca", "WET", "WEST"],
  ["Africa/Ceuta", "CET", "CEST"],
  ["Africa/Conakry", "GMT", null],
  ["Africa/Dakar", "GMT", null],
  ["Africa/Dar_es_Salaam", "EAT", null],
  ["Africa/Djibouti", "EAT", null],
  ["Africa/Douala", "WAT", null],
  ["Africa/El_Aaiun", "WET", "WEST"],
  ["Africa/Freetown", "GMT", null],
  ["Africa/Gaborone", "CAT", null],
  ["Africa/Harare", "CAT", null],
  ["Africa/Johannesburg", "SAST", null],
  ["Africa/Juba", "EAT", null],
  ["Africa/Kampala", "EAT", null],
  ["Africa/Khartoum", "EAT", null],
  ["Africa/Kigali", "CAT", null],
  ["Africa/Kinshasa", "WAT", null],
  ["Africa/Lagos", "WAT", null],
  ["Africa/Libreville", "WAT", null],
  ["Africa/Lome", "GMT", null],
  ["Africa/Luanda", "WAT", null],
  ["Africa/Lubumbashi", "CAT", null],
  ["Africa/Lusaka", "CAT", null],
  ["Africa/Malabo", "WAT", null],
  ["Africa/Maputo", "CAT", null],
  ["Africa/Maseru", "SAST", null],
  ["Africa/Mbabane", "SAST", null],
  ["Africa/Mogadishu", "EAT", null],
  ["Africa/Monrovia", "GMT", null],
  ["Africa/Nairobi", "EAT", null],
  ["Africa/Ndjamena", "WAT", null],
  ["Africa/Niamey", "WAT", null],
  ["Africa/Nouakchott", "GMT", null],
  ["Africa/Ouagadougou", "GMT", null],
  ["Africa/Porto-Novo", "WAT", null],
  ["Africa/Porto_Novo", "WAT", null],
  ["Africa/Sao_Tome", "GMT", null],
  ["Africa/Timbuktu", "GMT", null],
  ["Africa/Tripoli", "EET", null],
  ["Africa/Tunis", "CET", null],
  ["Africa/Windhoek", "WAT", "WAST"],
  ["America/Adak", "HST", "HDT"],
  ["America/Anchorage", "AKST", "AKDT"],
  ["America/Anguilla", "AST", null],
  ["America/Antigua", "AST", null],
  ["America/Araguaina", "BRT", null],
  ["America/Argentina/Buenos_Aires", "ART", null],
  ["America/Argentina/Catamarca", "ART", null],
  ["America/Argentina/ComodRivadavia", "ART", null],
  ["America/Argentina/Cordoba", "ART", null],
  ["America/Argentina/Jujuy", "ART", null],
  ["America/Argentina/La_Rioja", "ART", null],
  ["America/Argentina/Mendoza", "ART", null],
  ["America/Argentina/Rio_Gallegos", "ART", null],
  ["America/Argentina/Salta", "ART", null],
  ["America/Argentina/San_Juan", "ART", null],
  ["America/Argentina/San_Luis", "ART", null],
  ["America/Argentina/Tucuman", "ART", null],
  ["America/Argentina/Ushuaia", "ART", null],
  ["America/Aruba", "AST", null],
  ["America/Asuncion", "PYT", "PYST"],
  ["America/Atikokan", "EST", null],
  ["America/Atka", "HST", "HDT"],
  ["America/Bahia", "BRT", null],
  ["America/Bahia_Banderas", "CST", "CDT"],
  ["America/Barbados", "AST", null],
  ["America/Belem", "BRT", null],
  ["America/Belize", "CST", null],
  ["America/Beulah", "CST", "CDT"],
  ["America/Blanc-Sablon", "AST", null],
  ["America/Blanc_Sablon", "AST", null],
  ["America/Boa_Vista", "AMT", null],
  ["America/Bogota", "COT", null],
  ["America/Boise", "MST", "MDT"],
  ["America/Buenos_Aires", "ART", null],
  ["America/Cambridge_Bay", "MST", "MDT"],
  ["America/Campo_Grande", "AMT", "AMST"],
  ["America/Cancun", "EST", null],
  ["America/Caracas", "VET", null],
  ["America/Catamarca", "ART", null],
  ["America/Cayenne", "GFT", null],
  ["America/Cayman", "EST", null],
  ["America/Center", "CST", "CDT"],
  ["America/Chicago", "CST", "CDT"],
  ["America/Chihuahua", "MST", "MDT"],
  ["America/ComodRivadavia", "ART", null],
  ["America/Coral_Harbour", "EST", null],
  ["America/Cordoba", "ART", null],
  ["America/Costa_Rica", "CST", null],
  ["America/Creston", "MST", null],
  ["America/Cuiaba", "AMT", "AMST"],
  ["America/Curacao", "AST", null],
  ["America/Danmarkshavn", "GMT", null],
  ["America/Dawson", "PST", "PDT"],
  ["America/Dawson_Creek", "MST", null],
  ["America/Denver", "MST", "MDT"],
  ["America/Detroit", "EST", "EDT"],
  ["America/Dominica", "AST", null],
  ["America/Edmonton", "MST", "MDT"],
  ["America/Eirunepe", "ACT", null],
  ["America/El_Salvador", "CST", null],
  ["America/Ensenada", "PST", "PDT"],
  ["America/Fortaleza", "BRT", null],
  ["America/Fort_Wayne", "EST", "EDT"],
  ["America/Glace_Bay", "AST", "ADT"],
  ["America/Godthab", "WGT", "WGST"],
  ["America/Goose_Bay", "AST", "ADT"],
  ["America/Grand_Turk", "AST", null],
  ["America/Grenada", "AST", null],
  ["America/Guadeloupe", "AST", null],
  ["America/Guatemala", "CST", null],
  ["America/Guayaquil", "ECT", null],
  ["America/Guyana", "GYT", null],
  ["America/Halifax", "AST", "ADT"],
  ["America/Havana", "CST", "CDT"],
  ["America/Hermosillo", "MST", null],
  ["America/Indiana/Indianapolis", "EST", "EDT"],
  ["America/Indiana/Knox", "CST", "CDT"],
  ["America/Indiana/Marengo", "EST", "EDT"],
  ["America/Indiana/Petersburg", "EST", "EDT"],
  ["America/Indiana/Tell_City", "CST", "CDT"],
  ["America/Indiana/Vevay", "EST", "EDT"],
  ["America/Indiana/Vincennes", "EST", "EDT"],
  ["America/Indiana/Winamac", "EST", "EDT"],
  ["America/Indianapolis", "EST", "EDT"],
  ["America/Inuvik", "MST", "MDT"],
  ["America/Iqaluit", "EST", "EDT"],
  ["America/Jamaica", "EST", null],
  ["America/Jujuy", "ART", null],
  ["America/Juneau", "AKST", "AKDT"],
  ["America/Kentucky/Louisville", "EST", "EDT"],
  ["America/Kentucky/Monticello", "EST", "EDT"],
  ["America/Knox", "CST", "CDT"],
  ["America/Knox_IN", "CST", "CDT"],
  ["America/Kralendijk", "AST", null],
  ["America/La_Paz", "BOT", null],
  ["America/La_Rioja", "ART", null],
  ["America/Lima", "PET", null],
  ["America/Los_Angeles", "PST", "PDT"],
  ["America/Louisville", "EST", "EDT"],
  ["America/Lower_Princes", "AST", null],
  ["America/Maceio", "BRT", null],
  ["America/Managua", "CST", null],
  ["America/Manaus", "AMT", null],
  ["America/Marengo", "EST", "EDT"],
  ["America/Marigot", "AST", null],
  ["America/Martinique", "AST", null],
  ["America/Matamoros", "CST", "CDT"],
  ["America/Mazatlan", "MST", "MDT"],
  ["America/Mendoza", "ART", null],
  ["America/Menominee", "CST", "CDT"],
  ["America/Merida", "CST", "CDT"],
  ["America/Metlakatla", "AKST", "AKDT"],
  ["America/Mexico_City", "CST", "CDT"],
  ["America/Miquelon", "PMST", "PMDT"],
  ["America/Moncton", "AST", "ADT"],
  ["America/Monterrey", "CST", "CDT"],
  ["America/Montevideo", "UYT", null],
  ["America/Monticello", "EST", "EDT"],
  ["America/Montreal", "EST", "EDT"],
  ["America/Montserrat", "AST", null],
  ["America/Nassau", "EST", "EDT"],
  ["America/New_Salem", "CST", "CDT"],
  ["America/New_York", "EST", "EDT"],
  ["America/Nipigon", "EST", "EDT"],
  ["America/Nome", "AKST", "AKDT"],
  ["America/Noronha", "FNT", null],
  ["America/North_Dakota/Beulah", "CST", "CDT"],
  ["America/North_Dakota/Center", "CST", "CDT"],
  ["America/North_Dakota/New_Salem", "CST", "CDT"],
  ["America/Ojinaga", "MST", "MDT"],
  ["America/Panama", "EST", null],
  ["America/Pangnirtung", "EST", "EDT"],
  ["America/Paramaribo", "SRT", null],
  ["America/Petersburg", "EST", "EDT"],
  ["America/Phoenix", "MST", null],
  ["America/Port-au-Prince", "EST", null],
  ["America/Porto_Acre", "ACT", null],
  ["America/Porto_Velho", "AMT", null],
  ["America/Port_au_Prince", "EST", null],
  ["America/Port_of_Spain", "AST", null],
  ["America/Puerto_Rico", "AST", null],
  ["America/Rainy_River", "CST", "CDT"],
  ["America/Rankin_Inlet", "CST", "CDT"],
  ["America/Recife", "BRT", null],
  ["America/Regina", "CST", null],
  ["America/Resolute", "CST", "CDT"],
  ["America/Rio_Branco", "ACT", null],
  ["America/Rio_Gallegos", "ART", null],
  ["America/Rosario", "ART", null],
  ["America/Salta", "ART", null],
  ["America/Santarem", "BRT", null],
  ["America/Santa_Isabel", "PST", "PDT"],
  ["America/Santiago", "CLT", "CLST"],
  ["America/Santo_Domingo", "AST", null],
  ["America/San_Juan", "ART", null],
  ["America/San_Luis", "ART", null],
  ["America/Sao_Paulo", "BRT", "BRST"],
  ["America/Scoresbysund", "EGT", "EGST"],
  ["America/Shiprock", "MST", "MDT"],
  ["America/Sitka", "AKST", "AKDT"],
  ["America/St_Barthelemy", "AST", null],
  ["America/St_Johns", "NST", "NDT"],
  ["America/St_Kitts", "AST", null],
  ["America/St_Lucia", "AST", null],
  ["America/St_Thomas", "AST", null],
  ["America/St_Vincent", "AST", null],
  ["America/Swift_Current", "CST", null],
  ["America/Tegucigalpa", "CST", null],
  ["America/Tell_City", "CST", "CDT"],
  ["America/Thule", "AST", "ADT"],
  ["America/Thunder_Bay", "EST", "EDT"],
  ["America/Tijuana", "PST", "PDT"],
  ["America/Toronto", "EST", "EDT"],
  ["America/Tortola", "AST", null],
  ["America/Tucuman", "ART", null],
  ["America/Ushuaia", "ART", null],
  ["America/Vancouver", "PST", "PDT"],
  ["America/Vevay", "EST", "EDT"],
  ["America/Vincennes", "EST", "EDT"],
  ["America/Virgin", "AST", null],
  ["America/Whitehorse", "PST", "PDT"],
  ["America/Winamac", "EST", "EDT"],
  ["America/Winnipeg", "CST", "CDT"],
  ["America/Yakutat", "AKST", "AKDT"],
  ["America/Yellowknife", "MST", "MDT"],
  ["Antarctica/Casey", "AWST", null],
  ["Antarctica/Davis", "DAVT", null],
  ["Antarctica/DumontDUrville", "DDUT", null],
  ["Antarctica/Macquarie", "MIST", null],
  ["Antarctica/Mawson", "MAWT", null],
  ["Antarctica/McMurdo", "NZST", "NZDT"],
  ["Antarctica/Palmer", "CLT", "CLST"],
  ["Antarctica/Rothera", "ROTT", null],
  ["Antarctica/South_Pole", "NZST", "NZDT"],
  ["Antarctica/Syowa", "SYOT", null],
  ["Antarctica/Troll", "UTC", "CEST"],
  ["Antarctica/Vostok", "VOST", null],
  ["Arctic/Longyearbyen", "CET", "CEST"],
  ["Asia/Aden", "AST", null],
  ["Asia/Almaty", "ALMT", null],
  ["Asia/Amman", "EET", "EEST"],
  ["Asia/Anadyr", "ANAT", null],
  ["Asia/Aqtau", "AQTT", null],
  ["Asia/Aqtobe", "AQTT", null],
  ["Asia/Ashgabat", "TMT", null],
  ["Asia/Ashkhabad", "TMT", null],
  ["Asia/Baghdad", "AST", null],
  ["Asia/Bahrain", "AST", null],
  ["Asia/Baku", "AZT", null],
  ["Asia/Bangkok", "ICT", null],
  ["Asia/Beirut", "EET", "EEST"],
  ["Asia/Bishkek", "KGT", null],
  ["Asia/Brunei", "BNT", null],
  ["Asia/Calcutta", "IST", null],
  ["Asia/Chita", "YAKT", null],
  ["Asia/Choibalsan", "CHOT", "CHOST"],
  ["Asia/Chongqing", "CST", null],
  ["Asia/Chungking", "CST", null],
  ["Asia/Colombo", "IST", null],
  ["Asia/Dacca", "BDT", null],
  ["Asia/Damascus", "EET", "EEST"],
  ["Asia/Dhaka", "BDT", null],
  ["Asia/Dili", "TLT", null],
  ["Asia/Dubai", "GST", null],
  ["Asia/Dushanbe", "TJT", null],
  ["Asia/Gaza", "EET", "EEST"],
  ["Asia/Harbin", "CST", null],
  ["Asia/Hebron", "EET", "EEST"],
  ["Asia/Hong_Kong", "HKT", null],
  ["Asia/Hovd", "HOVT", "HOVST"],
  ["Asia/Ho_Chi_Minh", "ICT", null],
  ["Asia/Irkutsk", "IRKT", null],
  ["Asia/Istanbul", "EET", "EEST"],
  ["Asia/Jakarta", "WIB", null],
  ["Asia/Jayapura", "WIT", null],
  ["Asia/Jerusalem", "IST", "IDT"],
  ["Asia/Kabul", "AFT", null],
  ["Asia/Kamchatka", "PETT", null],
  ["Asia/Karachi", "PKT", null],
  ["Asia/Kashgar", "XJT", null],
  ["Asia/Kathmandu", "NPT", null],
  ["Asia/Katmandu", "NPT", null],
  ["Asia/Khandyga", "YAKT", null],
  ["Asia/Kolkata", "IST", null],
  ["Asia/Krasnoyarsk", "KRAT", null],
  ["Asia/Kuala_Lumpur", "MYT", null],
  ["Asia/Kuching", "MYT", null],
  ["Asia/Kuwait", "AST", null],
  ["Asia/Macao", "CST", null],
  ["Asia/Macau", "CST", null],
  ["Asia/Magadan", "MAGT", null],
  ["Asia/Makassar", "WITA", null],
  ["Asia/Manila", "PHT", null],
  ["Asia/Muscat", "GST", null],
  ["Asia/Nicosia", "EET", "EEST"],
  ["Asia/Novokuznetsk", "KRAT", null],
  ["Asia/Novosibirsk", "NOVT", null],
  ["Asia/Omsk", "OMST", null],
  ["Asia/Oral", "ORAT", null],
  ["Asia/Phnom_Penh", "ICT", null],
  ["Asia/Pontianak", "WIB", null],
  ["Asia/Pyongyang", "KST", null],
  ["Asia/Qatar", "AST", null],
  ["Asia/Qyzylorda", "QYZT", null],
  ["Asia/Rangoon", "MMT", null],
  ["Asia/Riyadh", "AST", null],
  ["Asia/Saigon", "ICT", null],
  ["Asia/Sakhalin", "SAKT", null],
  ["Asia/Samarkand", "UZT", null],
  ["Asia/Seoul", "KST", null],
  ["Asia/Shanghai", "CST", null],
  ["Asia/Singapore", "SGT", null],
  ["Asia/Srednekolymsk", "SRET", null],
  ["Asia/Taipei", "CST", null],
  ["Asia/Tashkent", "UZT", null],
  ["Asia/Tbilisi", "GET", null],
  ["Asia/Tehran", "IRST", "IRDT"],
  ["Asia/Tel_Aviv", "IST", "IDT"],
  ["Asia/Thimbu", "BTT", null],
  ["Asia/Thimphu", "BTT", null],
  ["Asia/Tokyo", "JST", null],
  ["Asia/Ujung_Pandang", "WITA", null],
  ["Asia/Ulaanbaatar", "ULAT", "ULAST"],
  ["Asia/Ulan_Bator", "ULAT", "ULAST"],
  ["Asia/Urumqi", "XJT", null],
  ["Asia/Ust-Nera", "VLAT", null],
  ["Asia/Ust_Nera", "VLAT", null],
  ["Asia/Vientiane", "ICT", null],
  ["Asia/Vladivostok", "VLAT", null],
  ["Asia/Yakutsk", "YAKT", null],
  ["Asia/Yekaterinburg", "YEKT", null],
  ["Asia/Yerevan", "AMT", null],
  ["Atlantic/Azores", "AZOT", "AZOST"],
  ["Atlantic/Bermuda", "AST", "ADT"],
  ["Atlantic/Canary", "WET", "WEST"],
  ["Atlantic/Cape_Verde", "CVT", null],
  ["Atlantic/Faeroe", "WET", "WEST"],
  ["Atlantic/Faroe", "WET", "WEST"],
  ["Atlantic/Jan_Mayen", "CET", "CEST"],
  ["Atlantic/Madeira", "WET", "WEST"],
  ["Atlantic/Reykjavik", "GMT", null],
  ["Atlantic/South_Georgia", "GST", null],
  ["Atlantic/Stanley", "FKST", null],
  ["Atlantic/St_Helena", "GMT", null],
  ["Australia/ACT", "AEST", "AEDT"],
  ["Australia/Adelaide", "ACST", "ACDT"],
  ["Australia/Brisbane", "AEST", null],
  ["Australia/Broken_Hill", "ACST", "ACDT"],
  ["Australia/Canberra", "AEST", "AEDT"],
  ["Australia/Currie", "AEST", "AEDT"],
  ["Australia/Darwin", "ACST", null],
  ["Australia/Eucla", "ACWST", null],
  ["Australia/Hobart", "AEST", "AEDT"],
  ["Australia/LHI", "LHST", "LHDT"],
  ["Australia/Lindeman", "AEST", null],
  ["Australia/Lord_Howe", "LHST", "LHDT"],
  ["Australia/Melbourne", "AEST", "AEDT"],
  ["Australia/North", "ACST", null],
  ["Australia/NSW", "AEST", "AEDT"],
  ["Australia/Perth", "AWST", null],
  ["Australia/Queensland", "AEST", null],
  ["Australia/South", "ACST", "ACDT"],
  ["Australia/Sydney", "AEST", "AEDT"],
  ["Australia/Tasmania", "AEST", "AEDT"],
  ["Australia/Victoria", "AEST", "AEDT"],
  ["Australia/West", "AWST", null],
  ["Australia/Yancowinna", "ACST", "ACDT"],
  ["Brazil/Acre", "ACT", null],
  ["Brazil/DeNoronha", "FNT", null],
  ["Brazil/East", "BRT", "BRST"],
  ["Brazil/West", "AMT", null],
  ["Canada/Atlantic", "AST", "ADT"],
  ["Canada/Central", "CST", "CDT"],
  ["Canada/East-Saskatchewan", "CST", null],
  ["Canada/Eastern", "EST", "EDT"],
  ["Canada/East_Saskatchewan", "CST", null],
  ["Canada/Mountain", "MST", "MDT"],
  ["Canada/Newfoundland", "NST", "NDT"],
  ["Canada/Pacific", "PST", "PDT"],
  ["Canada/Saskatchewan", "CST", null],
  ["Canada/Yukon", "PST", "PDT"],
  ["Chile/Continental", "CLT", "CLST"],
  ["Chile/EasterIsland", "EAST", "EASST"],
  ["Etc/GMT", "GMT", null],
  ["Etc/Greenwich", "GMT", null],
  ["Etc/UCT", "UCT", null],
  ["Etc/Universal", "UTC", null],
  ["Etc/UTC", "UTC", null],
  ["Etc/Zulu", "UTC", null],
  ["Europe/Amsterdam", "CET", "CEST"],
  ["Europe/Andorra", "CET", "CEST"],
  ["Europe/Athens", "EET", "EEST"],
  ["Europe/Belfast", "GMT", "BST"],
  ["Europe/Belgrade", "CET", "CEST"],
  ["Europe/Berlin", "CET", "CEST"],
  ["Europe/Bratislava", "CET", "CEST"],
  ["Europe/Brussels", "CET", "CEST"],
  ["Europe/Bucharest", "EET", "EEST"],
  ["Europe/Budapest", "CET", "CEST"],
  ["Europe/Busingen", "CET", "CEST"],
  ["Europe/Chisinau", "EET", "EEST"],
  ["Europe/Copenhagen", "CET", "CEST"],
  ["Europe/Dublin", "GMT", "IST"],
  ["Europe/Gibraltar", "CET", "CEST"],
  ["Europe/Guernsey", "GMT", "BST"],
  ["Europe/Helsinki", "EET", "EEST"],
  ["Europe/Isle_of_Man", "GMT", "BST"],
  ["Europe/Istanbul", "EET", "EEST"],
  ["Europe/Jersey", "GMT", "BST"],
  ["Europe/Kaliningrad", "EET", null],
  ["Europe/Kiev", "EET", "EEST"],
  ["Europe/Lisbon", "WET", "WEST"],
  ["Europe/Ljubljana", "CET", "CEST"],
  ["Europe/London", "GMT", "BST"],
  ["Europe/Luxembourg", "CET", "CEST"],
  ["Europe/Madrid", "CET", "CEST"],
  ["Europe/Malta", "CET", "CEST"],
  ["Europe/Mariehamn", "EET", "EEST"],
  ["Europe/Minsk", "MSK", null],
  ["Europe/Monaco", "CET", "CEST"],
  ["Europe/Moscow", "MSK", null],
  ["Europe/Nicosia", "EET", "EEST"],
  ["Europe/Oslo", "CET", "CEST"],
  ["Europe/Paris", "CET", "CEST"],
  ["Europe/Podgorica", "CET", "CEST"],
  ["Europe/Prague", "CET", "CEST"],
  ["Europe/Riga", "EET", "EEST"],
  ["Europe/Rome", "CET", "CEST"],
  ["Europe/Samara", "SAMT", null],
  ["Europe/San_Marino", "CET", "CEST"],
  ["Europe/Sarajevo", "CET", "CEST"],
  ["Europe/Simferopol", "MSK", null],
  ["Europe/Skopje", "CET", "CEST"],
  ["Europe/Sofia", "EET", "EEST"],
  ["Europe/Stockholm", "CET", "CEST"],
  ["Europe/Tallinn", "EET", "EEST"],
  ["Europe/Tirane", "CET", "CEST"],
  ["Europe/Tiraspol", "EET", "EEST"],
  ["Europe/Uzhgorod", "EET", "EEST"],
  ["Europe/Vaduz", "CET", "CEST"],
  ["Europe/Vatican", "CET", "CEST"],
  ["Europe/Vienna", "CET", "CEST"],
  ["Europe/Vilnius", "EET", "EEST"],
  ["Europe/Volgograd", "MSK", null],
  ["Europe/Warsaw", "CET", "CEST"],
  ["Europe/Zagreb", "CET", "CEST"],
  ["Europe/Zaporozhye", "EET", "EEST"],
  ["Europe/Zurich", "CET", "CEST"],
  ["Indian/Antananarivo", "EAT", null],
  ["Indian/Chagos", "IOT", null],
  ["Indian/Christmas", "CXT", null],
  ["Indian/Cocos", "CCT", null],
  ["Indian/Comoro", "EAT", null],
  ["Indian/Kerguelen", "TFT", null],
  ["Indian/Mahe", "SCT", null],
  ["Indian/Maldives", "MVT", null],
  ["Indian/Mauritius", "MUT", null],
  ["Indian/Mayotte", "EAT", null],
  ["Indian/Reunion", "RET", null],
  ["Mexico/BajaNorte", "PST", "PDT"],
  ["Mexico/BajaSur", "MST", "MDT"],
  ["Mexico/General", "CST", "CDT"],
  ["Pacific/Apia", "WSST", "WSDT"],
  ["Pacific/Auckland", "NZST", "NZDT"],
  ["Pacific/Chatham", "CHAST", "CHADT"],
  ["Pacific/Chuuk", "CHUT", null],
  ["Pacific/Easter", "EAST", "EASST"],
  ["Pacific/Efate", "VUT", null],
  ["Pacific/Enderbury", "PHOT", null],
  ["Pacific/Fakaofo", "TKT", null],
  ["Pacific/Fiji", "FJT", "FJST"],
  ["Pacific/Funafuti", "TVT", null],
  ["Pacific/Galapagos", "GALT", null],
  ["Pacific/Gambier", "GAMT", null],
  ["Pacific/Guadalcanal", "SBT", null],
  ["Pacific/Guam", "ChST", null],
  ["Pacific/Honolulu", "HST", null],
  ["Pacific/Johnston", "HST", null],
  ["Pacific/Kiritimati", "LINT", null],
  ["Pacific/Kosrae", "KOST", null],
  ["Pacific/Kwajalein", "MHT", null],
  ["Pacific/Majuro", "MHT", null],
  ["Pacific/Marquesas", "MART", null],
  ["Pacific/Midway", "SST", null],
  ["Pacific/Nauru", "NRT", null],
  ["Pacific/Niue", "NUT", null],
  ["Pacific/Norfolk", "NFT", null],
  ["Pacific/Noumea", "NCT", null],
  ["Pacific/Pago_Pago", "SST", null],
  ["Pacific/Palau", "PWT", null],
  ["Pacific/Pitcairn", "PST", null],
  ["Pacific/Pohnpei", "PONT", null],
  ["Pacific/Ponape", "PONT", null],
  ["Pacific/Port_Moresby", "PGT", null],
  ["Pacific/Rarotonga", "CKT", null],
  ["Pacific/Saipan", "ChST", null],
  ["Pacific/Samoa", "SST", null],
  ["Pacific/Tahiti", "TAHT", null],
  ["Pacific/Tarawa", "GILT", null],
  ["Pacific/Tongatapu", "TOT", null],
  ["Pacific/Truk", "CHUT", null],
  ["Pacific/Wake", "WAKT", null],
  ["Pacific/Wallis", "WFT", null],
  ["Pacific/Yap", "CHUT", null],
];

/* Get the two abbreviations from TZ name */
function GetTZAbbrs(name) {
  for (var i=0; i<tzNamesDB.length; i++) {
    var row = tzNamesDB[i];
    if (row[0].toUpperCase() == name.toUpperCase()) {
      return [row[1], row[2]];
    }
  }
  return ["TZ?", "DTS?"];
}

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function        JSON		                                      |
|                                                                             |
|   Description     Douglas Crockford's JSON object definition		      |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes           JScript does not natively support JSON.                   |
|                   Copied the content of the public domain json2.js from     |
|                   https://github.com/douglascrockford/JSON-js               |
|                                                                             |
|   History                                                                   |
|    2017-11-28 JFL Copied the content of the public domain json2.js.         |
*                                                                             *
\*---------------------------------------------------------------------------*/

if (!this.JSON) { // Just in case future versions of cscript do support it

//  json2.js
//  2016-10-28
//  Public Domain.
//  NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.
//  See http://www.JSON.org/js.html
//  This code should be minified before deployment.
//  See http://javascript.crockford.com/jsmin.html

//  USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
//  NOT CONTROL.

//  This file creates a global JSON object containing two methods: stringify
//  and parse. This file provides the ES5 JSON capability to ES3 systems.
//  If a project might run on IE8 or earlier, then this file should be included.
//  This file does nothing on ES5 systems.

//      JSON.stringify(value, replacer, space)
//          value       any JavaScript value, usually an object or array.
//          replacer    an optional parameter that determines how object
//                      values are stringified for objects. It can be a
//                      function or an array of strings.
//          space       an optional parameter that specifies the indentation
//                      of nested structures. If it is omitted, the text will
//                      be packed without extra whitespace. If it is a number,
//                      it will specify the number of spaces to indent at each
//                      level. If it is a string (such as "\t" or "&nbsp;"),
//                      it contains the characters used to indent at each level.
//          This method produces a JSON text from a JavaScript value.
//          When an object value is found, if the object contains a toJSON
//          method, its toJSON method will be called and the result will be
//          stringified. A toJSON method does not serialize: it returns the
//          value represented by the name/value pair that should be serialized,
//          or undefined if nothing should be serialized. The toJSON method
//          will be passed the key associated with the value, and this will be
//          bound to the value.

//          For example, this would serialize Dates as ISO strings.

//              Date.prototype.toJSON = function (key) {
//                  function f(n) {
//                      // Format integers to have at least two digits.
//                      return (n < 10)
//                          ? "0" + n
//                          : n;
//                  }
//                  return this.getUTCFullYear()   + "-" +
//                       f(this.getUTCMonth() + 1) + "-" +
//                       f(this.getUTCDate())      + "T" +
//                       f(this.getUTCHours())     + ":" +
//                       f(this.getUTCMinutes())   + ":" +
//                       f(this.getUTCSeconds())   + "Z";
//              };

//          You can provide an optional replacer method. It will be passed the
//          key and value of each member, with this bound to the containing
//          object. The value that is returned from your method will be
//          serialized. If your method returns undefined, then the member will
//          be excluded from the serialization.

//          If the replacer parameter is an array of strings, then it will be
//          used to select the members to be serialized. It filters the results
//          such that only members with keys listed in the replacer array are
//          stringified.

//          Values that do not have JSON representations, such as undefined or
//          functions, will not be serialized. Such values in objects will be
//          dropped; in arrays they will be replaced with null. You can use
//          a replacer function to replace those with JSON values.

//          JSON.stringify(undefined) returns undefined.

//          The optional space parameter produces a stringification of the
//          value that is filled with line breaks and indentation to make it
//          easier to read.

//          If the space parameter is a non-empty string, then that string will
//          be used for indentation. If the space parameter is a number, then
//          the indentation will be that many spaces.

//          Example:

//          text = JSON.stringify(["e", {pluribus: "unum"}]);
//          // text is '["e",{"pluribus":"unum"}]'

//          text = JSON.stringify(["e", {pluribus: "unum"}], null, "\t");
//          // text is '[\n\t"e",\n\t{\n\t\t"pluribus": "unum"\n\t}\n]'

//          text = JSON.stringify([new Date()], function (key, value) {
//              return this[key] instanceof Date
//                  ? "Date(" + this[key] + ")"
//                  : value;
//          });
//          // text is '["Date(---current time---)"]'

//      JSON.parse(text, reviver)
//          This method parses a JSON text to produce an object or array.
//          It can throw a SyntaxError exception.

//          The optional reviver parameter is a function that can filter and
//          transform the results. It receives each of the keys and values,
//          and its return value is used instead of the original value.
//          If it returns what it received, then the structure is not modified.
//          If it returns undefined then the member is deleted.

//          Example:

//          // Parse the text. Values that look like ISO date strings will
//          // be converted to Date objects.

//          myData = JSON.parse(text, function (key, value) {
//              var a;
//              if (typeof value === "string") {
//                  a =
//   /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value);
//                  if (a) {
//                      return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4],
//                          +a[5], +a[6]));
//                  }
//              }
//              return value;
//          });

//          myData = JSON.parse('["Date(09/09/2001)"]', function (key, value) {
//              var d;
//              if (typeof value === "string" &&
//                      value.slice(0, 5) === "Date(" &&
//                      value.slice(-1) === ")") {
//                  d = new Date(value.slice(5, -1));
//                  if (d) {
//                      return d;
//                  }
//              }
//              return value;
//          });

//  This is a reference implementation. You are free to copy, modify, or
//  redistribute.

/*jslint
    eval, for, this
*/

/*property
    JSON, apply, call, charCodeAt, getUTCDate, getUTCFullYear, getUTCHours,
    getUTCMinutes, getUTCMonth, getUTCSeconds, hasOwnProperty, join,
    lastIndex, length, parse, prototype, push, replace, slice, stringify,
    test, toJSON, toString, valueOf
*/


// Create a JSON object only if one does not already exist. We create the
// methods in a closure to avoid creating global variables.

if (typeof JSON !== "object") {
    JSON = {};
}

(function () {
    "use strict";

    var rx_one = /^[\],:{}\s]*$/;
    var rx_two = /\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g;
    var rx_three = /"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g;
    var rx_four = /(?:^|:|,)(?:\s*\[)+/g;
    var rx_escapable = /[\\"\u0000-\u001f\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
    var rx_dangerous = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;

    function f(n) {
        // Format integers to have at least two digits.
        return n < 10
            ? "0" + n
            : n;
    }

    function this_value() {
        return this.valueOf();
    }

    if (typeof Date.prototype.toJSON !== "function") {

        Date.prototype.toJSON = function () {

            return isFinite(this.valueOf())
                ? this.getUTCFullYear() + "-" +
                        f(this.getUTCMonth() + 1) + "-" +
                        f(this.getUTCDate()) + "T" +
                        f(this.getUTCHours()) + ":" +
                        f(this.getUTCMinutes()) + ":" +
                        f(this.getUTCSeconds()) + "Z"
                : null;
        };

        Boolean.prototype.toJSON = this_value;
        Number.prototype.toJSON = this_value;
        String.prototype.toJSON = this_value;
    }

    var gap;
    var indent;
    var meta;
    var rep;


    function quote(string) {

// If the string contains no control characters, no quote characters, and no
// backslash characters, then we can safely slap some quotes around it.
// Otherwise we must also replace the offending characters with safe escape
// sequences.

        rx_escapable.lastIndex = 0;
        return rx_escapable.test(string)
            ? "\"" + string.replace(rx_escapable, function (a) {
                var c = meta[a];
                return typeof c === "string"
                    ? c
                    : "\\u" + ("0000" + a.charCodeAt(0).toString(16)).slice(-4);
            }) + "\""
            : "\"" + string + "\"";
    }


    function str(key, holder) {

// Produce a string from holder[key].

        var i;          // The loop counter.
        var k;          // The member key.
        var v;          // The member value.
        var length;
        var mind = gap;
        var partial;
        var value = holder[key];

// If the value has a toJSON method, call it to obtain a replacement value.

        if (value && typeof value === "object" &&
                typeof value.toJSON === "function") {
            value = value.toJSON(key);
        }

// If we were called with a replacer function, then call the replacer to
// obtain a replacement value.

        if (typeof rep === "function") {
            value = rep.call(holder, key, value);
        }

// What happens next depends on the value's type.

        switch (typeof value) {
        case "string":
            return quote(value);

        case "number":

// JSON numbers must be finite. Encode non-finite numbers as null.

            return isFinite(value)
                ? String(value)
                : "null";

        case "boolean":
        case "null":

// If the value is a boolean or null, convert it to a string. Note:
// typeof null does not produce "null". The case is included here in
// the remote chance that this gets fixed someday.

            return String(value);

// If the type is "object", we might be dealing with an object or an array or
// null.

        case "object":

// Due to a specification blunder in ECMAScript, typeof null is "object",
// so watch out for that case.

            if (!value) {
                return "null";
            }

// Make an array to hold the partial results of stringifying this object value.

            gap += indent;
            partial = [];

// Is the value an array?

            if (Object.prototype.toString.apply(value) === "[object Array]") {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || "null";
                }

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

                v = partial.length === 0
                    ? "[]"
                    : gap
                        ? "[\n" + gap + partial.join(",\n" + gap) + "\n" + mind + "]"
                        : "[" + partial.join(",") + "]";
                gap = mind;
                return v;
            }

// If the replacer is an array, use it to select the members to be stringified.

            if (rep && typeof rep === "object") {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    if (typeof rep[i] === "string") {
                        k = rep[i];
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (
                                gap
                                    ? ": "
                                    : ":"
                            ) + v);
                        }
                    }
                }
            } else {

// Otherwise, iterate through all of the keys in the object.

                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (
                                gap
                                    ? ": "
                                    : ":"
                            ) + v);
                        }
                    }
                }
            }

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

            v = partial.length === 0
                ? "{}"
                : gap
                    ? "{\n" + gap + partial.join(",\n" + gap) + "\n" + mind + "}"
                    : "{" + partial.join(",") + "}";
            gap = mind;
            return v;
        }
    }

// If the JSON object does not yet have a stringify method, give it one.

    if (typeof JSON.stringify !== "function") {
        meta = {    // table of character substitutions
            "\b": "\\b",
            "\t": "\\t",
            "\n": "\\n",
            "\f": "\\f",
            "\r": "\\r",
            "\"": "\\\"",
            "\\": "\\\\"
        };
        JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

            var i;
            gap = "";
            indent = "";

// If the space parameter is a number, make an indent string containing that
// many spaces.

            if (typeof space === "number") {
                for (i = 0; i < space; i += 1) {
                    indent += " ";
                }

// If the space parameter is a string, it will be used as the indent string.

            } else if (typeof space === "string") {
                indent = space;
            }

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

            rep = replacer;
            if (replacer && typeof replacer !== "function" &&
                    (typeof replacer !== "object" ||
                    typeof replacer.length !== "number")) {
                throw new Error("JSON.stringify");
            }

// Make a fake root object containing our value under the key of "".
// Return the result of stringifying the value.

            return str("", {"": value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== "function") {
        JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

            var j;

            function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

                var k;
                var v;
                var value = holder[key];
                if (value && typeof value === "object") {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

            text = String(text);
            rx_dangerous.lastIndex = 0;
            if (rx_dangerous.test(text)) {
                text = text.replace(rx_dangerous, function (a) {
                    return "\\u" +
                            ("0000" + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }

// In the second stage, we run the text against regular expressions that look
// for non-JSON patterns. We are especially concerned with "()" and "new"
// because they can cause invocation, and "=" because it can cause mutation.
// But just to be safe, we want to reject all unexpected forms.

// We split the second stage into 4 regexp operations in order to work around
// crippling inefficiencies in IE's and Safari's regexp engines. First we
// replace the JSON backslash pairs with "@" (a non-JSON character). Second, we
// replace all simple value tokens with "]" characters. Third, we delete all
// open brackets that follow a colon or comma or that begin the text. Finally,
// we look to see that the remaining characters are only whitespace or "]" or
// "," or ":" or "{" or "}". If that is so, then the text is safe for eval.

            if (
                rx_one.test(
                    text
                        .replace(rx_two, "@")
                        .replace(rx_three, "]")
                        .replace(rx_four, "")
                )
            ) {

// In the third stage we use the eval function to compile the text into a
// JavaScript structure. The "{" operator is subject to a syntactic ambiguity
// in JavaScript: it can begin a block or an object literal. We wrap the text
// in parens to eliminate the ambiguity.

                j = eval("(" + text + ")");

// In the optional fourth stage, we recursively walk the new structure, passing
// each name/value pair to a reviver function for possible transformation.

                return (typeof reviver === "function")
                    ? walk({"": j}, "")
                    : j;
            }

// If the text is not JSON parseable, then a SyntaxError is thrown.

            throw new SyntaxError("JSON.parse");
        };
    }
}());

} // End protection against future built-in support for JSON

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function        CreateXhrObject	                                      |
|                                                                             |
|   Description     Create an XMLHttpRequest ActiveX object	 	      |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes           Adapted from the sample in: 			      |
|		    https://fr.wikipedia.org/wiki/XMLHttpRequest              |
|                                                                             |
|   History                                                                   |
|    2017-11-28 JFL Simplified the public domain sample in Wikipedia.         |
*                                                                             *
\*---------------------------------------------------------------------------*/

function CreateXhrObject() {
    // The list of safe versions that we can try to use is documented there:
    // https://blogs.msdn.microsoft.com/xmlteam/2006/10/23/using-the-right-version-of-msxml-in-internet-explorer/
    var names = [
	"Msxml2.XMLHTTP.6.0",
	"Msxml2.XMLHTTP.3.0",
	"Msxml2.XMLHTTP",
	"Microsoft.XMLHTTP"
    ];
    for (var i in names) {
	try { return new ActiveXObject(names[i]); }
	catch(e){}
    }
    throw new FatalError("No support for XMLHttpRequest ActiveX object");
}

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function        Execute an XMLHttp or Rest Request                        |
|                                                                             |
|   Description     Get and post HTTP requests, w. the XMLHttpRequest ActiveX |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes           https://fr.wikipedia.org/wiki/XMLHttpRequest              |
|                   https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
|                   https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest
|                                                                             |
|   History                                                                   |
|    2017-11-24 JFL Created this routine.                                     |
|    2019-11-14 JFL Added option['xml'] to optionally return the XML DOM obj. |
|    2024-03-24 JFL Added lots of debug output.	Added the format argument.    |
|                   Added support for REST requests results encoded in JSON.  |
*                                                                             *
\*---------------------------------------------------------------------------*/

/**
* @desc  Get and post HTTP requests, w. the XMLHttpRequest ActiveX
* @param string url	The request url
* @param string verb	The http verb. Ex: "GET" or "POST"
* @param string data	The optional data to send with a POST
* @param string format	Output data format. "xml" or "json" or default = raw text output
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError  Message describing an XMLHttpRequest (connection) or HTTP (web server) error
* @return  The raw text output returned by the server, or if format is "json" or "xml", the JavaScript object represented by that text,
*/
function ExecRequest(url, verb, data, format, options) {
  options = (typeof options === 'undefined') ? defaultOptions : options;
  if (options["debug"] > 1) WScript.Echo("ExecRequest(\"" + url + "\", \"" + verb + "\", \"" + data + "\", \"" + format + "\")");
  data = (typeof data === 'undefined') ? null : data;
  var xhr = CreateXhrObject();
  xhr.open(verb, url, false);
  // An ActiveXObject object has no intrinsic properties or methods; it allows you to access the properties and methods of the Automation object.
  // Here's a set of known getter properties for the xhr XMLHttpRequest ActiveXObject:
  var keys = ['timeout', 'withCredentials', 'upload', 'responseURL', 'status', 'statusText', 'responseType', /* 'response', */ 'responseText' /* , 'responseXML' */];
  if (options['debug'] > 1) {
    WScript.Echo("Input: xhr = {");
    for (var i in keys) try { var key=keys[i]; var value = xhr[key]; if (typeof value !== 'undefined') WScript.Echo("  " + key + " = " + value); } catch (e) {};
    WScript.Echo("}");
  }
  if (options['debug']) WScript.Echo("GET " + url);
  try {
    xhr.send(data);
  } catch (e) { /* Change the error type to ours */
    throw new FatalError(e.message); // Connection failure
  }
  if (options['debug']) {
    WScript.Echo("Output: xhr = {");
    for (var i in keys) try { var key=keys[i]; var value = xhr[key]; if (typeof value !== 'undefined') WScript.Echo("  " + key + " = " + value); } catch (e) {};
    WScript.Echo("}");
    headers = Trim(xhr.getAllResponseHeaders(), "\r\n"); // They usually end by two empty lines: \r\n\r\n
    WScript.Echo("headers = {\n" + Indent(headers) + "\n}");
  }
  if (xhr.status != 200) { /* Then the web server failed to fulfill the request */
    throw new FatalError("HTTP error " + xhr.status + ": " + xhr.statusText);
  }
  // WScript.Echo("return '$response'");
  switch (format) {
    case 'xml': return xhr.responseXML;
    case 'json': return JSON.parse(xhr.responseText);
    default: return xhr.responseText;
  }
}

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function        XMLHttpRequest functions                                  |
|                                                                             |
|   Description     Execute XMLHttpRequests, w. the XMLHttpRequest ActiveX    |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes           https://xhr.spec.whatwg.org/                              |
|                   https://fr.wikipedia.org/wiki/XMLHttpRequest              |
|                   https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
|                   https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest
|                                                                             |
|   History                                                                   |
|    2019-11-14 JFL Created these routines.                                   |
*                                                                             *
\*---------------------------------------------------------------------------*/

/**
* @desc  Get the output from an XMLHttpRequest API
* @param string url  The request url
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError  Message describing an XMLHttpRequest (connection) or HTTP (web server) error
* @return  The XML document returned by the server
*/
function GetXMLHttpRequest(url, options) {
  options = (typeof options === 'undefined') ? defaultOptions : options;
  if (options["debug"] > 1) WScript.Echo("GetXMLHttpRequest(\"" + url + "\")");
  return ExecRequest(url, 'GET', null, 'xml', options);
}

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function	    FreeGeoIP API functions	                              |
|                                                                             |
|   Description     Invoke the FreeGeoIP location API			      |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes                                                                     |
|                                                                             |
|   History                                                                   |
|    2019-11-13 JFL Created these routines.	                              |
*                                                                             *
\*---------------------------------------------------------------------------*/

var urlFreeGeoIP = "https://freegeoip.app";	// Old Application server URL
var urlFreeGeoIP = "https://freegeoip.io";	// Another Application server URL
var urlFreeGeoIP = "https://api.ipbase.com/v1";	// New Application server URL

/**
* @desc  Invoke the FreeGeoIP location API, and return the raw results
* @param string api The server API. Ex: "/xml/" or "/json/"
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) or puload API error
* @return The JSON or XML string returned by the server.
*/
function LocationApi(api, options) {
  options = (typeof options === 'undefined') ? defaultOptions : options;
  if (options["debug"] > 1) WScript.Echo("LocationApi(\"" + api + "\")");

  // Get the URL of one of the  APIs above
  var url = urlFreeGeoIP + api;

  // Call the REST API
  response = ExecRequest(url, 'GET', null, options['format'], options);

  // Show the response as a JavaScript object, even if it's an XML response
  if (options['debug']) WScript.Echo("# " + api + " result: " + JSON.stringify(response, null, "  "));
  return response;
}

/**
* @desc  Invoke the FreeGeoIP location API, and decode the result
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) or puload API error
* @return The XML returned by the server, converted to a JavaScript array.
*/
function GetLocation(options) {
  options = (typeof options === 'undefined') ? defaultOptions : options;
  if (options["debug"] > 1) WScript.Echo("GetLocation()");
  var format = options['format'];
  var url = urlFreeGeoIP + '/' + format + '/';
  if (options["server"]) url += options["server"];
  var result = ExecRequest(url, 'GET', null, format, options);
  if (format == 'xml') { // Extract the location information from the XML document object 
    var doc = result;
    if (doc == null) {
      if (options['debug']) WScript.Echo("XML doc is null");
      return null;
    }
    var root = doc.documentElement;
    var children = root.childNodes;
    result = [];
    for (var i=0; i<children.length; i++) {
      child = children.item(i);
      if (child.nodeType != 1) continue; // Skip text nodes, if any
      var name = child.tagName;
      var value = "";
      var grandchildren = child.childNodes;
      for (var j=0; j<grandchildren.length; j++) {
	grand = grandchildren.item(j);
	if (grand.nodeType != 3) continue; // Expecting only text nodes here
	value += grand.data;
      }
      result[name] = value;
    }
  }
  return result;
}

/*---------------------------------------------------------------------------*\
*                                                                             *
|   Function        main                                                      |
|                                                                             |
|   Description     Process command-line arguments                            |
|                                                                             |
|   Arguments                                                                 |
|                                                                             |
|   Returns                                                                   |
|                                                                             |
|   Notes                                                                     |
|                                                                             |
|   History                                                                   |
|    2019-11-13 JFL Created these routine.                                    |
*                                                                             *
\*---------------------------------------------------------------------------*/

// Execute the rest of this file only when it's invoked as a standalone script
// var isCLI = !module.parent;
// var isCLI = require.main === module;
if ((typeof module == 'undefined') || !module.parent) {

    // Test if an argument is a switch or not
    function isSwitch(arg) {
        // Switches begin by a "-". (Which is the standard for Unix shells, but not for Windows')
        // Exception: By convention, the file name "-" means stdin or stdout.
        return ((arg == "/?") || ((arg.substring(0,1) == "-") && (arg != "-")));
    }

    // Display a help screen
    function usage() {
        WScript.Echo("\
WhereAmI.bat - Get system location information, based on its IP address\n\
\n\
Usage: WhereAmI [OPTIONS] [SERVER|IP]\n\
\n\
Options:\n\
  -d        Debug mode: Display internal infos about how things work\n\
  -j        Display the freegeoip.app JSON response\n\
  -s        Save the system location data into file %windir%\\location.inf\n\
            (Recommended for today/sunrise/sunset. Must be running as Admin.)\n\
  -u        Save the user location data into file %USERPROFILE%\\location.inf\n\
            (Alternative for today/sunrise/sunset, when not running as Admin.)\n\
  -v        Verbose mode: Display more details about what is being done\n\
  -V        Display the script version\n\
  -x        Display the freegeoip.app XML response\n\
\n\
Server|IP: The DNS name or IP address of another system. Default: This system's\n\
\n\
Note: Uses https://freegeoip.app/. This requires a connection to the Internet.\
");
    }

    function getOptionalArgument(argv, i) {
        var arg = null;
        if (((i+1) < argv.length) && !isSwitch(argv[i+1])) arg = argv[++i];
        return arg;
    }

    // Process command-line arguments, and run the requested commands
    function main(argc, argv) {
        var options = defaultOptions;
        var action = 'list';
        var api = 'json'; // As of 2024, the FreeGeoIP xml API is obsolete, and not supported anymore
        var noexec = false;
        var server = "";

        for (i=1; i < argc; i++) {
            var arg = argv[i];
            if (isSwitch(arg)) { // This is an option
                var opt = arg.substring(1);
                switch (opt) {
                case '?':
                case 'h':
                case '-help':
                    usage();
                    return 0;
                case 'd':       // Debug
                    options["debug"] += 1;
		    // WScript.Echo("JScript version " + @_jscript_version);
                    continue;
                case 'j':       // Get JSON location information
		    action = 'dump';
                    api = 'json';
                    continue;
                case 's':       // Save the %windir%/location.inf configuration file
		    action = 'system';
                    api = 'xml';
                    continue;
                case 'u':       // Save the %USERPROFILE%/location.inf configuration file
		    action = 'user';
                    api = 'xml';
                    continue;
                case 'v':       // Verbose
                    options["verbose"] = true;
                    continue;
                case 'V':
                case '-version':
                    WScript.Echo(VERSION);
                    return 0;
                case 'x':       // Get XML location information
		    action = 'dump';
                    api = 'xml';
                    continue;
                case 'X':       // no-exec mode
                case '-noexec':
		    noexec = true;
                    api = 'xml';
                    continue;
                default:
                    throw new FatalError("Invalid option: " + arg);
                }
            }
            // Then process normal arguments
            if (server == "") {
              server = arg;
              continue;
            }
	    throw new FatalError("Invalid argument: " + arg);
        }

        // The FreeGeoIP API name is the same as the output format name
        switch (api) {
        case 'xml':
        case 'json':
	    options["format"] = api;
	    break;
        }

        // In debug mode, show the options
        if (options["debug"]) {
          WScript.Echo("options = {");
	  for (var key in options) try {
	    var value = options[key]; WScript.Echo("  " + key + " = " + value);
	  } catch (e) {};
          WScript.Echo("}");
	}

        // Show the service queried
        api = "/" + api + "/" + server;
        if (options["verbose"] || options["debug"]) {
	    var url = urlFreeGeoIP + api;
	    WScript.Echo("# GET " + url);
	}

        switch (action) { // Merge the following two into a single "save" action
        case 'system':
	    var shell = new ActiveXObject("WScript.Shell");
	    var GetEnvVar = shell.Environment("Process");
	    var windir = GetEnvVar("windir");
	    var filename = windir + "\\location.inf";
	    action = "save";
	    break;
        case 'user':
	    var shell = new ActiveXObject("WScript.Shell");
	    var GetEnvVar = shell.Environment("Process");
	    var home = GetEnvVar("USERPROFILE");
	    var filename = home + "\\location.inf";
	    action = "save";
	    break;
        }

        switch (action) { // Merge the following two into a single "list" action
        case 'list':
	    var ts = WScript.StdOut;	// Output Text Stream = stdout
	    break;
        case 'save':			// Create an fso Text Stream object
	    WScript.Echo("Writing location data to \"" + filename + "\"");
	    if (!noexec) {
	      var fso = new ActiveXObject("Scripting.FileSystemObject");
	      var ts = fso.CreateTextFile(filename, true);
	    } else {
	      var ts = WScript.StdOut;
	    }
	    action = "list";
	    break;
        }

        switch (action) {
        case 'dump':
	    // Show the response as a JavaScript object, even if it's an XML response
	    WScript.Echo(JSON.stringify(LocationApi(api, options), null, "  "));
	    break;
        case 'list':
          options["server"] = server;
	  result = GetLocation(options);
	  for (var v in result) {
	    var tag = v.toUpperCase();
	    var value = result[v];
	    ts.WriteLine(tag + " = " + value);
	    if (tag == "TIMEZONE") {
	      var abbrs = GetTZAbbrs(value);
	      ts.WriteLine("TZABBR = " + abbrs[0]);
	      ts.WriteLine("DSTABBR = " + abbrs[1]);
	    }
	  }
	  if (ts != WScript.StdOut) ts.Close();
	  break;
        }
        return 0;
    }

    // Top level code, executed when running this module as a standalone script
    try {
	var argv = [WScript.ScriptFullName];
	var argc = 1 + WScript.Arguments.Length;
	for (var i=1; i<argc; i++) argv[i] = WScript.Arguments.item(i-1);
	var exitCode = main(argc, argv);
    } catch (e) {
        if (e.name == "FatalError") {	// Our own "controlled" errors
	    WScript.Stderr.WriteLine('Error: ' + e.message);
	    exitCode = 1;
	} else {			// Out-of-control failures
	    if (!e.stack) { // Unfortunately the JScript version in cscript does not support this property
	      throw e;		// So throw it again, so that cscript displays all internal details.
	    }
	    // Display the exception details and stack trace
	    WScript.Stderr.WriteLine('JScript error: ' + e.message);
	    WScript.Stderr.Write(e.stack.toString());
	    exitCode = 2;
	}
    }
    WScript.Quit(exitCode);
}
