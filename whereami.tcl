#!/usr/bin/tclsh
###############################################################################
#                                                                             #
#   File name	    whereami.tcl                                              #
#                                                                             #
#   Description     Get the system location based on its IP address           #
#                                                                             #
#   Notes:	    Uses the APIs on https://freegeoip.app/                   #
#                                                                             #
#                   Works on both Unix and Windows.                           #
#                                                                             #
#                   On Unix, this requires the tcllib and tcltls packages.    #
#                   If they're not installed, run, for example:               #
#                   yum install tcllib tcltls                                 #
#                                                                             #
#                   On windows, requires installing a Tcl interpreter,        #
#                   and configuring it to run *.tcl scripts as command-line   #
#                   scripts. For explanations on how to do that, see:         #
#                   https://github.com/JFLarvoire/SysToolsLib/tree/master/Tcl #
#                                                                             #
#   Authors:	    JFL jf.larvoire@free.fr				      #
#                                                                             #
#   History:								      #
#    2019-11-15 JFL Created this script.                                      #
#    2019-11-16 JFL Added the DB of time zone names, and set TZABBR, DSTZABBR.#
#    2019-11-17 JFL Added options -s & -u to write respectively a system      #
#		    configuration file, and a user configuration file.        #
#    2019-11-18 JFL Fixed the configuration file name for Windows.	      #
#                                                                             #
###############################################################################

# Set defaults
set version "2019-11-18"

set script [file tail $argv0]

package require http

# Remove an argument from the head of a routine argument list.
proc PopArg {{name args}} {
  upvar 1 $name args
  set arg [lindex $args 0]              ; # Extract the first list element.
  set args [lrange $args 1 end]         ; # Remove the first list element.
  return $arg
}

#-----------------------------------------------------------------------------#
# Database of timezone names
# Adapted from Boost date_time_zonespec.csv at
# https://github.com/boostorg/date_time/blob/master/data/date_time_zonespec.csv
# See Boost copyright at https://github.com/boostorg/date_time/blob/develop/LICENSE
foreach {name TZ DSTZ} {
  "Africa/Abidjan" "GMT" ""
  "Africa/Accra" "GMT" ""
  "Africa/Addis_Ababa" "EAT" ""
  "Africa/Algiers" "CET" ""
  "Africa/Asmara" "EAT" ""
  "Africa/Asmera" "EAT" ""
  "Africa/Bamako" "GMT" ""
  "Africa/Bangui" "WAT" ""
  "Africa/Banjul" "GMT" ""
  "Africa/Bissau" "GMT" ""
  "Africa/Blantyre" "CAT" ""
  "Africa/Brazzaville" "WAT" ""
  "Africa/Bujumbura" "CAT" ""
  "Africa/Cairo" "EET" ""
  "Africa/Casablanca" "WET" "WEST"
  "Africa/Ceuta" "CET" "CEST"
  "Africa/Conakry" "GMT" ""
  "Africa/Dakar" "GMT" ""
  "Africa/Dar_es_Salaam" "EAT" ""
  "Africa/Djibouti" "EAT" ""
  "Africa/Douala" "WAT" ""
  "Africa/El_Aaiun" "WET" "WEST"
  "Africa/Freetown" "GMT" ""
  "Africa/Gaborone" "CAT" ""
  "Africa/Harare" "CAT" ""
  "Africa/Johannesburg" "SAST" ""
  "Africa/Juba" "EAT" ""
  "Africa/Kampala" "EAT" ""
  "Africa/Khartoum" "EAT" ""
  "Africa/Kigali" "CAT" ""
  "Africa/Kinshasa" "WAT" ""
  "Africa/Lagos" "WAT" ""
  "Africa/Libreville" "WAT" ""
  "Africa/Lome" "GMT" ""
  "Africa/Luanda" "WAT" ""
  "Africa/Lubumbashi" "CAT" ""
  "Africa/Lusaka" "CAT" ""
  "Africa/Malabo" "WAT" ""
  "Africa/Maputo" "CAT" ""
  "Africa/Maseru" "SAST" ""
  "Africa/Mbabane" "SAST" ""
  "Africa/Mogadishu" "EAT" ""
  "Africa/Monrovia" "GMT" ""
  "Africa/Nairobi" "EAT" ""
  "Africa/Ndjamena" "WAT" ""
  "Africa/Niamey" "WAT" ""
  "Africa/Nouakchott" "GMT" ""
  "Africa/Ouagadougou" "GMT" ""
  "Africa/Porto-Novo" "WAT" ""
  "Africa/Porto_Novo" "WAT" ""
  "Africa/Sao_Tome" "GMT" ""
  "Africa/Timbuktu" "GMT" ""
  "Africa/Tripoli" "EET" ""
  "Africa/Tunis" "CET" ""
  "Africa/Windhoek" "WAT" "WAST"
  "America/Adak" "HST" "HDT"
  "America/Anchorage" "AKST" "AKDT"
  "America/Anguilla" "AST" ""
  "America/Antigua" "AST" ""
  "America/Araguaina" "BRT" ""
  "America/Argentina/Buenos_Aires" "ART" ""
  "America/Argentina/Catamarca" "ART" ""
  "America/Argentina/ComodRivadavia" "ART" ""
  "America/Argentina/Cordoba" "ART" ""
  "America/Argentina/Jujuy" "ART" ""
  "America/Argentina/La_Rioja" "ART" ""
  "America/Argentina/Mendoza" "ART" ""
  "America/Argentina/Rio_Gallegos" "ART" ""
  "America/Argentina/Salta" "ART" ""
  "America/Argentina/San_Juan" "ART" ""
  "America/Argentina/San_Luis" "ART" ""
  "America/Argentina/Tucuman" "ART" ""
  "America/Argentina/Ushuaia" "ART" ""
  "America/Aruba" "AST" ""
  "America/Asuncion" "PYT" "PYST"
  "America/Atikokan" "EST" ""
  "America/Atka" "HST" "HDT"
  "America/Bahia" "BRT" ""
  "America/Bahia_Banderas" "CST" "CDT"
  "America/Barbados" "AST" ""
  "America/Belem" "BRT" ""
  "America/Belize" "CST" ""
  "America/Beulah" "CST" "CDT"
  "America/Blanc-Sablon" "AST" ""
  "America/Blanc_Sablon" "AST" ""
  "America/Boa_Vista" "AMT" ""
  "America/Bogota" "COT" ""
  "America/Boise" "MST" "MDT"
  "America/Buenos_Aires" "ART" ""
  "America/Cambridge_Bay" "MST" "MDT"
  "America/Campo_Grande" "AMT" "AMST"
  "America/Cancun" "EST" ""
  "America/Caracas" "VET" ""
  "America/Catamarca" "ART" ""
  "America/Cayenne" "GFT" ""
  "America/Cayman" "EST" ""
  "America/Center" "CST" "CDT"
  "America/Chicago" "CST" "CDT"
  "America/Chihuahua" "MST" "MDT"
  "America/ComodRivadavia" "ART" ""
  "America/Coral_Harbour" "EST" ""
  "America/Cordoba" "ART" ""
  "America/Costa_Rica" "CST" ""
  "America/Creston" "MST" ""
  "America/Cuiaba" "AMT" "AMST"
  "America/Curacao" "AST" ""
  "America/Danmarkshavn" "GMT" ""
  "America/Dawson" "PST" "PDT"
  "America/Dawson_Creek" "MST" ""
  "America/Denver" "MST" "MDT"
  "America/Detroit" "EST" "EDT"
  "America/Dominica" "AST" ""
  "America/Edmonton" "MST" "MDT"
  "America/Eirunepe" "ACT" ""
  "America/El_Salvador" "CST" ""
  "America/Ensenada" "PST" "PDT"
  "America/Fortaleza" "BRT" ""
  "America/Fort_Wayne" "EST" "EDT"
  "America/Glace_Bay" "AST" "ADT"
  "America/Godthab" "WGT" "WGST"
  "America/Goose_Bay" "AST" "ADT"
  "America/Grand_Turk" "AST" ""
  "America/Grenada" "AST" ""
  "America/Guadeloupe" "AST" ""
  "America/Guatemala" "CST" ""
  "America/Guayaquil" "ECT" ""
  "America/Guyana" "GYT" ""
  "America/Halifax" "AST" "ADT"
  "America/Havana" "CST" "CDT"
  "America/Hermosillo" "MST" ""
  "America/Indiana/Indianapolis" "EST" "EDT"
  "America/Indiana/Knox" "CST" "CDT"
  "America/Indiana/Marengo" "EST" "EDT"
  "America/Indiana/Petersburg" "EST" "EDT"
  "America/Indiana/Tell_City" "CST" "CDT"
  "America/Indiana/Vevay" "EST" "EDT"
  "America/Indiana/Vincennes" "EST" "EDT"
  "America/Indiana/Winamac" "EST" "EDT"
  "America/Indianapolis" "EST" "EDT"
  "America/Inuvik" "MST" "MDT"
  "America/Iqaluit" "EST" "EDT"
  "America/Jamaica" "EST" ""
  "America/Jujuy" "ART" ""
  "America/Juneau" "AKST" "AKDT"
  "America/Kentucky/Louisville" "EST" "EDT"
  "America/Kentucky/Monticello" "EST" "EDT"
  "America/Knox" "CST" "CDT"
  "America/Knox_IN" "CST" "CDT"
  "America/Kralendijk" "AST" ""
  "America/La_Paz" "BOT" ""
  "America/La_Rioja" "ART" ""
  "America/Lima" "PET" ""
  "America/Los_Angeles" "PST" "PDT"
  "America/Louisville" "EST" "EDT"
  "America/Lower_Princes" "AST" ""
  "America/Maceio" "BRT" ""
  "America/Managua" "CST" ""
  "America/Manaus" "AMT" ""
  "America/Marengo" "EST" "EDT"
  "America/Marigot" "AST" ""
  "America/Martinique" "AST" ""
  "America/Matamoros" "CST" "CDT"
  "America/Mazatlan" "MST" "MDT"
  "America/Mendoza" "ART" ""
  "America/Menominee" "CST" "CDT"
  "America/Merida" "CST" "CDT"
  "America/Metlakatla" "AKST" "AKDT"
  "America/Mexico_City" "CST" "CDT"
  "America/Miquelon" "PMST" "PMDT"
  "America/Moncton" "AST" "ADT"
  "America/Monterrey" "CST" "CDT"
  "America/Montevideo" "UYT" ""
  "America/Monticello" "EST" "EDT"
  "America/Montreal" "EST" "EDT"
  "America/Montserrat" "AST" ""
  "America/Nassau" "EST" "EDT"
  "America/New_Salem" "CST" "CDT"
  "America/New_York" "EST" "EDT"
  "America/Nipigon" "EST" "EDT"
  "America/Nome" "AKST" "AKDT"
  "America/Noronha" "FNT" ""
  "America/North_Dakota/Beulah" "CST" "CDT"
  "America/North_Dakota/Center" "CST" "CDT"
  "America/North_Dakota/New_Salem" "CST" "CDT"
  "America/Ojinaga" "MST" "MDT"
  "America/Panama" "EST" ""
  "America/Pangnirtung" "EST" "EDT"
  "America/Paramaribo" "SRT" ""
  "America/Petersburg" "EST" "EDT"
  "America/Phoenix" "MST" ""
  "America/Port-au-Prince" "EST" ""
  "America/Porto_Acre" "ACT" ""
  "America/Porto_Velho" "AMT" ""
  "America/Port_au_Prince" "EST" ""
  "America/Port_of_Spain" "AST" ""
  "America/Puerto_Rico" "AST" ""
  "America/Rainy_River" "CST" "CDT"
  "America/Rankin_Inlet" "CST" "CDT"
  "America/Recife" "BRT" ""
  "America/Regina" "CST" ""
  "America/Resolute" "CST" "CDT"
  "America/Rio_Branco" "ACT" ""
  "America/Rio_Gallegos" "ART" ""
  "America/Rosario" "ART" ""
  "America/Salta" "ART" ""
  "America/Santarem" "BRT" ""
  "America/Santa_Isabel" "PST" "PDT"
  "America/Santiago" "CLT" "CLST"
  "America/Santo_Domingo" "AST" ""
  "America/San_Juan" "ART" ""
  "America/San_Luis" "ART" ""
  "America/Sao_Paulo" "BRT" "BRST"
  "America/Scoresbysund" "EGT" "EGST"
  "America/Shiprock" "MST" "MDT"
  "America/Sitka" "AKST" "AKDT"
  "America/St_Barthelemy" "AST" ""
  "America/St_Johns" "NST" "NDT"
  "America/St_Kitts" "AST" ""
  "America/St_Lucia" "AST" ""
  "America/St_Thomas" "AST" ""
  "America/St_Vincent" "AST" ""
  "America/Swift_Current" "CST" ""
  "America/Tegucigalpa" "CST" ""
  "America/Tell_City" "CST" "CDT"
  "America/Thule" "AST" "ADT"
  "America/Thunder_Bay" "EST" "EDT"
  "America/Tijuana" "PST" "PDT"
  "America/Toronto" "EST" "EDT"
  "America/Tortola" "AST" ""
  "America/Tucuman" "ART" ""
  "America/Ushuaia" "ART" ""
  "America/Vancouver" "PST" "PDT"
  "America/Vevay" "EST" "EDT"
  "America/Vincennes" "EST" "EDT"
  "America/Virgin" "AST" ""
  "America/Whitehorse" "PST" "PDT"
  "America/Winamac" "EST" "EDT"
  "America/Winnipeg" "CST" "CDT"
  "America/Yakutat" "AKST" "AKDT"
  "America/Yellowknife" "MST" "MDT"
  "Antarctica/Casey" "AWST" ""
  "Antarctica/Davis" "DAVT" ""
  "Antarctica/DumontDUrville" "DDUT" ""
  "Antarctica/Macquarie" "MIST" ""
  "Antarctica/Mawson" "MAWT" ""
  "Antarctica/McMurdo" "NZST" "NZDT"
  "Antarctica/Palmer" "CLT" "CLST"
  "Antarctica/Rothera" "ROTT" ""
  "Antarctica/South_Pole" "NZST" "NZDT"
  "Antarctica/Syowa" "SYOT" ""
  "Antarctica/Troll" "UTC" "CEST"
  "Antarctica/Vostok" "VOST" ""
  "Arctic/Longyearbyen" "CET" "CEST"
  "Asia/Aden" "AST" ""
  "Asia/Almaty" "ALMT" ""
  "Asia/Amman" "EET" "EEST"
  "Asia/Anadyr" "ANAT" ""
  "Asia/Aqtau" "AQTT" ""
  "Asia/Aqtobe" "AQTT" ""
  "Asia/Ashgabat" "TMT" ""
  "Asia/Ashkhabad" "TMT" ""
  "Asia/Baghdad" "AST" ""
  "Asia/Bahrain" "AST" ""
  "Asia/Baku" "AZT" ""
  "Asia/Bangkok" "ICT" ""
  "Asia/Beirut" "EET" "EEST"
  "Asia/Bishkek" "KGT" ""
  "Asia/Brunei" "BNT" ""
  "Asia/Calcutta" "IST" ""
  "Asia/Chita" "YAKT" ""
  "Asia/Choibalsan" "CHOT" "CHOST"
  "Asia/Chongqing" "CST" ""
  "Asia/Chungking" "CST" ""
  "Asia/Colombo" "IST" ""
  "Asia/Dacca" "BDT" ""
  "Asia/Damascus" "EET" "EEST"
  "Asia/Dhaka" "BDT" ""
  "Asia/Dili" "TLT" ""
  "Asia/Dubai" "GST" ""
  "Asia/Dushanbe" "TJT" ""
  "Asia/Gaza" "EET" "EEST"
  "Asia/Harbin" "CST" ""
  "Asia/Hebron" "EET" "EEST"
  "Asia/Hong_Kong" "HKT" ""
  "Asia/Hovd" "HOVT" "HOVST"
  "Asia/Ho_Chi_Minh" "ICT" ""
  "Asia/Irkutsk" "IRKT" ""
  "Asia/Istanbul" "EET" "EEST"
  "Asia/Jakarta" "WIB" ""
  "Asia/Jayapura" "WIT" ""
  "Asia/Jerusalem" "IST" "IDT"
  "Asia/Kabul" "AFT" ""
  "Asia/Kamchatka" "PETT" ""
  "Asia/Karachi" "PKT" ""
  "Asia/Kashgar" "XJT" ""
  "Asia/Kathmandu" "NPT" ""
  "Asia/Katmandu" "NPT" ""
  "Asia/Khandyga" "YAKT" ""
  "Asia/Kolkata" "IST" ""
  "Asia/Krasnoyarsk" "KRAT" ""
  "Asia/Kuala_Lumpur" "MYT" ""
  "Asia/Kuching" "MYT" ""
  "Asia/Kuwait" "AST" ""
  "Asia/Macao" "CST" ""
  "Asia/Macau" "CST" ""
  "Asia/Magadan" "MAGT" ""
  "Asia/Makassar" "WITA" ""
  "Asia/Manila" "PHT" ""
  "Asia/Muscat" "GST" ""
  "Asia/Nicosia" "EET" "EEST"
  "Asia/Novokuznetsk" "KRAT" ""
  "Asia/Novosibirsk" "NOVT" ""
  "Asia/Omsk" "OMST" ""
  "Asia/Oral" "ORAT" ""
  "Asia/Phnom_Penh" "ICT" ""
  "Asia/Pontianak" "WIB" ""
  "Asia/Pyongyang" "KST" ""
  "Asia/Qatar" "AST" ""
  "Asia/Qyzylorda" "QYZT" ""
  "Asia/Rangoon" "MMT" ""
  "Asia/Riyadh" "AST" ""
  "Asia/Saigon" "ICT" ""
  "Asia/Sakhalin" "SAKT" ""
  "Asia/Samarkand" "UZT" ""
  "Asia/Seoul" "KST" ""
  "Asia/Shanghai" "CST" ""
  "Asia/Singapore" "SGT" ""
  "Asia/Srednekolymsk" "SRET" ""
  "Asia/Taipei" "CST" ""
  "Asia/Tashkent" "UZT" ""
  "Asia/Tbilisi" "GET" ""
  "Asia/Tehran" "IRST" "IRDT"
  "Asia/Tel_Aviv" "IST" "IDT"
  "Asia/Thimbu" "BTT" ""
  "Asia/Thimphu" "BTT" ""
  "Asia/Tokyo" "JST" ""
  "Asia/Ujung_Pandang" "WITA" ""
  "Asia/Ulaanbaatar" "ULAT" "ULAST"
  "Asia/Ulan_Bator" "ULAT" "ULAST"
  "Asia/Urumqi" "XJT" ""
  "Asia/Ust-Nera" "VLAT" ""
  "Asia/Ust_Nera" "VLAT" ""
  "Asia/Vientiane" "ICT" ""
  "Asia/Vladivostok" "VLAT" ""
  "Asia/Yakutsk" "YAKT" ""
  "Asia/Yekaterinburg" "YEKT" ""
  "Asia/Yerevan" "AMT" ""
  "Atlantic/Azores" "AZOT" "AZOST"
  "Atlantic/Bermuda" "AST" "ADT"
  "Atlantic/Canary" "WET" "WEST"
  "Atlantic/Cape_Verde" "CVT" ""
  "Atlantic/Faeroe" "WET" "WEST"
  "Atlantic/Faroe" "WET" "WEST"
  "Atlantic/Jan_Mayen" "CET" "CEST"
  "Atlantic/Madeira" "WET" "WEST"
  "Atlantic/Reykjavik" "GMT" ""
  "Atlantic/South_Georgia" "GST" ""
  "Atlantic/Stanley" "FKST" ""
  "Atlantic/St_Helena" "GMT" ""
  "Australia/ACT" "AEST" "AEDT"
  "Australia/Adelaide" "ACST" "ACDT"
  "Australia/Brisbane" "AEST" ""
  "Australia/Broken_Hill" "ACST" "ACDT"
  "Australia/Canberra" "AEST" "AEDT"
  "Australia/Currie" "AEST" "AEDT"
  "Australia/Darwin" "ACST" ""
  "Australia/Eucla" "ACWST" ""
  "Australia/Hobart" "AEST" "AEDT"
  "Australia/LHI" "LHST" "LHDT"
  "Australia/Lindeman" "AEST" ""
  "Australia/Lord_Howe" "LHST" "LHDT"
  "Australia/Melbourne" "AEST" "AEDT"
  "Australia/North" "ACST" ""
  "Australia/NSW" "AEST" "AEDT"
  "Australia/Perth" "AWST" ""
  "Australia/Queensland" "AEST" ""
  "Australia/South" "ACST" "ACDT"
  "Australia/Sydney" "AEST" "AEDT"
  "Australia/Tasmania" "AEST" "AEDT"
  "Australia/Victoria" "AEST" "AEDT"
  "Australia/West" "AWST" ""
  "Australia/Yancowinna" "ACST" "ACDT"
  "Brazil/Acre" "ACT" ""
  "Brazil/DeNoronha" "FNT" ""
  "Brazil/East" "BRT" "BRST"
  "Brazil/West" "AMT" ""
  "Canada/Atlantic" "AST" "ADT"
  "Canada/Central" "CST" "CDT"
  "Canada/East-Saskatchewan" "CST" ""
  "Canada/Eastern" "EST" "EDT"
  "Canada/East_Saskatchewan" "CST" ""
  "Canada/Mountain" "MST" "MDT"
  "Canada/Newfoundland" "NST" "NDT"
  "Canada/Pacific" "PST" "PDT"
  "Canada/Saskatchewan" "CST" ""
  "Canada/Yukon" "PST" "PDT"
  "Chile/Continental" "CLT" "CLST"
  "Chile/EasterIsland" "EAST" "EASST"
  "Etc/GMT" "GMT" ""
  "Etc/Greenwich" "GMT" ""
  "Etc/UCT" "UCT" ""
  "Etc/Universal" "UTC" ""
  "Etc/UTC" "UTC" ""
  "Etc/Zulu" "UTC" ""
  "Europe/Amsterdam" "CET" "CEST"
  "Europe/Andorra" "CET" "CEST"
  "Europe/Athens" "EET" "EEST"
  "Europe/Belfast" "GMT" "BST"
  "Europe/Belgrade" "CET" "CEST"
  "Europe/Berlin" "CET" "CEST"
  "Europe/Bratislava" "CET" "CEST"
  "Europe/Brussels" "CET" "CEST"
  "Europe/Bucharest" "EET" "EEST"
  "Europe/Budapest" "CET" "CEST"
  "Europe/Busingen" "CET" "CEST"
  "Europe/Chisinau" "EET" "EEST"
  "Europe/Copenhagen" "CET" "CEST"
  "Europe/Dublin" "GMT" "IST"
  "Europe/Gibraltar" "CET" "CEST"
  "Europe/Guernsey" "GMT" "BST"
  "Europe/Helsinki" "EET" "EEST"
  "Europe/Isle_of_Man" "GMT" "BST"
  "Europe/Istanbul" "EET" "EEST"
  "Europe/Jersey" "GMT" "BST"
  "Europe/Kaliningrad" "EET" ""
  "Europe/Kiev" "EET" "EEST"
  "Europe/Lisbon" "WET" "WEST"
  "Europe/Ljubljana" "CET" "CEST"
  "Europe/London" "GMT" "BST"
  "Europe/Luxembourg" "CET" "CEST"
  "Europe/Madrid" "CET" "CEST"
  "Europe/Malta" "CET" "CEST"
  "Europe/Mariehamn" "EET" "EEST"
  "Europe/Minsk" "MSK" ""
  "Europe/Monaco" "CET" "CEST"
  "Europe/Moscow" "MSK" ""
  "Europe/Nicosia" "EET" "EEST"
  "Europe/Oslo" "CET" "CEST"
  "Europe/Paris" "CET" "CEST"
  "Europe/Podgorica" "CET" "CEST"
  "Europe/Prague" "CET" "CEST"
  "Europe/Riga" "EET" "EEST"
  "Europe/Rome" "CET" "CEST"
  "Europe/Samara" "SAMT" ""
  "Europe/San_Marino" "CET" "CEST"
  "Europe/Sarajevo" "CET" "CEST"
  "Europe/Simferopol" "MSK" ""
  "Europe/Skopje" "CET" "CEST"
  "Europe/Sofia" "EET" "EEST"
  "Europe/Stockholm" "CET" "CEST"
  "Europe/Tallinn" "EET" "EEST"
  "Europe/Tirane" "CET" "CEST"
  "Europe/Tiraspol" "EET" "EEST"
  "Europe/Uzhgorod" "EET" "EEST"
  "Europe/Vaduz" "CET" "CEST"
  "Europe/Vatican" "CET" "CEST"
  "Europe/Vienna" "CET" "CEST"
  "Europe/Vilnius" "EET" "EEST"
  "Europe/Volgograd" "MSK" ""
  "Europe/Warsaw" "CET" "CEST"
  "Europe/Zagreb" "CET" "CEST"
  "Europe/Zaporozhye" "EET" "EEST"
  "Europe/Zurich" "CET" "CEST"
  "Indian/Antananarivo" "EAT" ""
  "Indian/Chagos" "IOT" ""
  "Indian/Christmas" "CXT" ""
  "Indian/Cocos" "CCT" ""
  "Indian/Comoro" "EAT" ""
  "Indian/Kerguelen" "TFT" ""
  "Indian/Mahe" "SCT" ""
  "Indian/Maldives" "MVT" ""
  "Indian/Mauritius" "MUT" ""
  "Indian/Mayotte" "EAT" ""
  "Indian/Reunion" "RET" ""
  "Mexico/BajaNorte" "PST" "PDT"
  "Mexico/BajaSur" "MST" "MDT"
  "Mexico/General" "CST" "CDT"
  "Pacific/Apia" "WSST" "WSDT"
  "Pacific/Auckland" "NZST" "NZDT"
  "Pacific/Chatham" "CHAST" "CHADT"
  "Pacific/Chuuk" "CHUT" ""
  "Pacific/Easter" "EAST" "EASST"
  "Pacific/Efate" "VUT" ""
  "Pacific/Enderbury" "PHOT" ""
  "Pacific/Fakaofo" "TKT" ""
  "Pacific/Fiji" "FJT" "FJST"
  "Pacific/Funafuti" "TVT" ""
  "Pacific/Galapagos" "GALT" ""
  "Pacific/Gambier" "GAMT" ""
  "Pacific/Guadalcanal" "SBT" ""
  "Pacific/Guam" "ChST" ""
  "Pacific/Honolulu" "HST" ""
  "Pacific/Johnston" "HST" ""
  "Pacific/Kiritimati" "LINT" ""
  "Pacific/Kosrae" "KOST" ""
  "Pacific/Kwajalein" "MHT" ""
  "Pacific/Majuro" "MHT" ""
  "Pacific/Marquesas" "MART" ""
  "Pacific/Midway" "SST" ""
  "Pacific/Nauru" "NRT" ""
  "Pacific/Niue" "NUT" ""
  "Pacific/Norfolk" "NFT" ""
  "Pacific/Noumea" "NCT" ""
  "Pacific/Pago_Pago" "SST" ""
  "Pacific/Palau" "PWT" ""
  "Pacific/Pitcairn" "PST" ""
  "Pacific/Pohnpei" "PONT" ""
  "Pacific/Ponape" "PONT" ""
  "Pacific/Port_Moresby" "PGT" ""
  "Pacific/Rarotonga" "CKT" ""
  "Pacific/Saipan" "ChST" ""
  "Pacific/Samoa" "SST" ""
  "Pacific/Tahiti" "TAHT" ""
  "Pacific/Tarawa" "GILT" ""
  "Pacific/Tongatapu" "TOT" ""
  "Pacific/Truk" "CHUT" ""
  "Pacific/Wake" "WAKT" ""
  "Pacific/Wallis" "WFT" ""
  "Pacific/Yap" "CHUT" ""
} {
  set name [string toupper $name]
  set TZDB($name) $TZ
  set DSTZDB($name) $DSTZ
}

###############################################################################
#                                Main routines                                #
###############################################################################

#-----------------------------------------------------------------------------#
#                                                                             #
#   Function	    Main                                        	      #
#                                                                             #
#   Description     Process command line arguments.                           #
#                                                                             #
#   Parameters      argc               The number of arguments                #
#                   argv               List of arguments                      #
#                                                                             #
#   Returns 	    0 if success                                              #
#                                                                             #
#   Notes:	                                                              #
#                                                                             #
#   History:								      #
#    2005/01/15 JFL Created this routine.                                     #
#                                                                             #
#-----------------------------------------------------------------------------#

# Usage string
if {$::tcl_platform(platform) == "windows"} {
  set systemProfile "%windir%\location.inf"
  set userProfile "%USERPROFILE%\location.inf"
  set root "Administrator"
} else { # Unix
  set systemProfile "/etc/location.conf"
  set userProfile "~/.location"
  set root "root"
}
set usage [subst -nobackslashes -nocommands {
$script - Get the system location based on its IP address

Usage: $script [OPTIONS] [SERVER|IP]

Options:
  -?|-h     Display this help
  -j        Display the freegeoip.app JSON response
  -s        Save the system location data into file $systemProfile
            (Recommended for today/sunrise/sunset. Must be running as $root.)
  -u        Save the user location data into file $userProfile
            (Alternative for today/sunrise/sunset, when not running as $root.)
  -V        Display the script version
  -x        Display the freegeoip.app XML response

Server|IP: The DNS name or IP address of another system. Default: This system's

Note: Uses https://freegeoip.app/. This requires a connection to the Internet.
}]

set usage [string range $usage 1 end]		;# Remove the initial \n
if {$::tcl_platform(platform) == "windows"} {
  set usage [string range $usage 0 end-1]	;# Remove the final \n
}

# Default settings
set action "list"
set api "json"
set host ""
set verbose 0

# Scan all arguments.
set args $argv
while {"$args" != ""} {
  set arg [PopArg]
  switch -- $arg {
    "-j" - "--json" {		# Dump the raw json data
      set api "json"
      set action "dump"
    }
    "-h" - "--help" - "-?" - "/?" {	# Display a help screen and exit.
      puts $usage
      exit 0
    }
    "-V" - "--version" {	# Display this library version
      puts $version
      puts [array get TZDB]
      exit 0
    }
    "-s" - "--system" {		# Save the /etc/location.conf configuration file
      set api "json"
      set action "system"
    }
    "-u" - "--user" {		# Save the ~/.location configuration file
      set api "json"
      set action "user"
    }
    "-v" - "--verbose" {	# Increase the verbosity level
      set verbose 1
    }
    "-x" - "--xml" {		# Dump the raw xml data
      set api "xml"
      set action "dump"
    }
    default {
      if {"$host"==""} {		; # If the host is not set...
	set host $arg   
      } else {                          ; # Anything else is an error.
        puts stderr "Unrecognized argument: $arg"
	exit 1
      }
    }
  }
}

# Only enforce these requirements now. This allows getting the help, even
# on systems that are missing the necessary packages.
set err [catch {
  set tlsVersion [package require tls]
  package require json
  
  # proc yes args { # Traces TLS handshake, and forces certificates validation
  #   puts "yes $args"
  #   return 1
  # }

  # Disable ssl3, as the ssl3 hadshake fails to connect to https://freegeoip.app/
  tls::init -require false -request false -ssl2 0 -ssl3 0 ;# -command ::yes
  # Work around issues in tls 1.6, which lacks init option -autoservername true
  proc tls_socket args {
    # puts "tls_socket $args"
    # set opts [lrange $args 0 end-2]
    set host [lindex $args end-1]
    # set port [lindex $args end]
    set cmd [concat ::tls::socket -servername $host $args]
    # puts $cmd
    eval $cmd
  }
  
  # http::register https 443 ::tls::socket	;# The default TLS socket
  http::register https 443 ::tls_socket		;# Our TLS socket front end
} errMsg]
if {$err} {
  set pkg tls
  regexp {package (\S+)} $errMsg - pkg
  if {$::tcl_platform(platform) == "windows"} {
    set msg "This script depends on the tls and json packages.
If they're not installed, please run, for example: teacup install $pkg"
  } else {
  set msg {This script depends on the tcllib and tcltls packages.
If they're not installed, please run, for example: yum install tcllib tcltls}
  }
  puts stderr "$script: Error: $errMsg\n$msg"
  exit 1
}

set url "https://freegeoip.app/$api/$host"

set err [catch {
  set token [http::geturl $url]

  set reply [http::data $token]

  # Merge the following two actions into a single "save" action
  switch $action {
    "system" {
      if {"$::tcl_platform(platform)" == "windows"} {
	set filename "$env(windir)\\location.inf"
      } else {
	set filename "/etc/location.conf"
      }
      set action "save"
    }
    "user" {
      if {"$::tcl_platform(platform)" == "windows"} {
	set filename "$env(USERPROFILE)\\location.inf"
      } else {
	set filename "$env(HOME)/.location"
      }
      set action "save"
    }
  }

  # Merge the following two actions into a single "list" action
  switch $action {
    "list" {
      set hFile "stdout"
    }
    "save" {
      puts "Writing location data to \"[file nativename $filename]\""
      set hFile [open $filename "w"]
      set action "list"
    }
  }

  switch $action {
    "dump" {
      puts -nonewline $reply
    }
    "list" {
      set data [json::json2dict $reply]
      foreach {key value} $data {
	set key [string toupper $key]
	regsub -all "_" $key "" key
	puts $hFile "$key = $value"
	if {$key == "TIMEZONE"} {
	  set tzNAME [string toupper $value]
	  catch {
	    set tzAbbr $TZDB($tzNAME)
	    puts $hFile "TZABBR = $tzAbbr"
	    set dstzAbbr $DSTZDB($tzNAME)
	    puts $hFile "DSTZABBR = $dstzAbbr"
	  }
	}
      }
      if {$hFile != "stdout"} {
	close $hFile
      }
    }
  }
} errMsg]
if $err {
  # Known issue with ActiveTcl 8.5:
  if {$errMsg == "wrong # args: should be \"tls::socket ?options? host port\""} {
    set errMsg "Old buggy version of tls detected. Please update the tls package"
    if {$::tcl_platform(platform) == "windows"} {
      set errMsg "$errMsg, or update to ActiveTcl 8.6"
    }
    set errMsg "$errMsg."
  }
  puts stderr "$script: $errMsg"
}
