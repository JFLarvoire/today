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
*                   https://technet.microsoft.com/en-us/library/ee156585.aspx *
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
*                                                                             *
\*****************************************************************************/

var VERSION = "2018-11-18" // Version string displayed by the -V | --version option

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
*                                                                             *
\*---------------------------------------------------------------------------*/

function ExecRequest(url, verb, data, options) {
    options = (typeof options === 'undefined') ? defaultOptions : options;
    data = (typeof data === 'undefined') ? null : data;
    var xhr = CreateXhrObject();
    xhr.open(verb, url, false);
    // if (options['debug']) { }
    // WScript.Echo("Before:");
    // for (var i in keys) try { var key=keys[i]; var value = xhr[key]; if (value) WScript.Echo("" + key + " = " + value); } catch (e) {};
    if (options['debug']) WScript.Echo("GET " + url);
    try {
	xhr.send(data);
    } catch (e) { /* Change the error type to ours */
	throw new FatalError(e.message); // Connection failure
    }
    // WScript.Echo("After:");
    // for (var i in keys) try { var key=keys[i]; var value = xhr[key]; if (value) WScript.Echo("" + key + " = " + value); } catch (e) {};
    // WScript.Echo("headers = \n" + xhr.getAllResponseHeaders());
    if (xhr.status != 200) { /* Then the web server failed to fulfill the request */
        throw new FatalError("HTTP error " + xhr.status + ": " + xhr.statusText);
    }
    // WScript.Echo("return '$response'");
    if (options['xml']) return xhr.responseXML;
    return xhr.responseText;
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
|   Notes           https://fr.wikipedia.org/wiki/XMLHttpRequest              |
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
    options['xml'] = true;
    return ExecRequest(url, 'GET', null, options);
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

var urlFreeGeoIP = "https://freegeoip.app";	// Application server

/**
* @desc  Invoke the FreeGeoIP location API, and return the raw results
* @param string api The server API. Ex: "/xml/" or "/json/"
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) or puload API error
* @return The JSON or XML string returned by the server.
*/
function LocationApi(api, options) {
    options = (typeof options === 'undefined') ? defaultOptions : options;

    // Get the URL of one of the  APIs above
    var url = urlFreeGeoIP + api;

    // Call the REST API
    if (options['debug']) WScript.Echo("GET " + url);
    response = ExecRequest(url, 'GET', null, options);

    if (options['debug']) WScript.Echo("# /" + api + " result: " + response);
    return response;
}

/**
* @desc  Invoke the FreeGeoIP location API, and decode the result
* @param array  options overriding script defaults. Ex: ["debug"=1]
* @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) or puload API error
* @return The XML returned by the server, converted to a PHP array.
*/
function GetLocation(options) {
    options = (typeof options === 'undefined') ? defaultOptions : options;
    var url = urlFreeGeoIP + '/xml/';
    if (options["server"]) url += options["server"];
    var doc = GetXMLHttpRequest(url, options);
    if (doc == null) {
      if (options['debug']) WScript.Echo("XML doc is null");
      return null;
    }
    var root = doc.documentElement;
    var children = root.childNodes;
    var result = [];
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
        var api = 'xml';
        var noexec = false;

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
            if (!options["server"]) {
              options["server"] = arg;
              continue;
            }
	    throw new FatalError("Invalid argument: " + arg);
        }

        // Run the requested action
        var url = "https://freegeoip.app/" + api + "/" + options["server"];
        if (options["verbose"]) {
	    WScript.Echo("# GET " + url);
	}
        result = GetLocation();

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
	    WScript.Echo(LocationApi('/xml/', options));
	    break;
        case 'list':
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
