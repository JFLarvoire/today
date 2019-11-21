#!/usr/bin/env python
###############################################################################
#                                                                             #
#   File name       whereami.py                                               #
#                                                                             #
#   Description     Get the system location based on its IP address           #
#                                                                             #
#   Notes:          Uses the APIs on https://freegeoip.app/                   #
#                                                                             #
#                   Works on both Unix and Windows.                           #
#                                                                             #
#                   This requires the requests package.                       #
#                                                                             #
#   Authors:        JFL jf.larvoire@free.fr                                   #
#                                                                             #
#   History:                                                                  #
#    2019-11-19 JFL Created this script.                                      #
#                                                                             #
###############################################################################

# Set defaults
VERSION = "2019-11-21" # Version string displayed by the -V | --version option

# Many functions in this module use these options by default:
defaultOptions = {"verbose":False, "debug":0}
# Use the argument: options = defaultOptions

import sys
import os
import traceback
import json

script = os.path.basename(__file__)

# Private class used to abort execution with an error message
class FatalError(Exception): pass
# Usage example: raise FatalError("This is impossible");
# When used as a standalone program, this error message is written to stderr:
# Error: This is impossible

#-----------------------------------------------------------------------------#
#  Database of timezone names
#  Adapted from Boost date_time_zonespec.csv at
#  https://github.com/boostorg/date_time/blob/master/data/date_time_zonespec.csv
#  See Boost copyright at https://github.com/boostorg/date_time/blob/develop/LICENSE
tzNamesDB = [
    # Full name, Abbreviation, DST Abbreviation
    ["Africa/Abidjan", "GMT", None],
    ["Africa/Accra", "GMT", None],
    ["Africa/Addis_Ababa", "EAT", None],
    ["Africa/Algiers", "CET", None],
    ["Africa/Asmara", "EAT", None],
    ["Africa/Asmera", "EAT", None],
    ["Africa/Bamako", "GMT", None],
    ["Africa/Bangui", "WAT", None],
    ["Africa/Banjul", "GMT", None],
    ["Africa/Bissau", "GMT", None],
    ["Africa/Blantyre", "CAT", None],
    ["Africa/Brazzaville", "WAT", None],
    ["Africa/Bujumbura", "CAT", None],
    ["Africa/Cairo", "EET", None],
    ["Africa/Casablanca", "WET", "WEST"],
    ["Africa/Ceuta", "CET", "CEST"],
    ["Africa/Conakry", "GMT", None],
    ["Africa/Dakar", "GMT", None],
    ["Africa/Dar_es_Salaam", "EAT", None],
    ["Africa/Djibouti", "EAT", None],
    ["Africa/Douala", "WAT", None],
    ["Africa/El_Aaiun", "WET", "WEST"],
    ["Africa/Freetown", "GMT", None],
    ["Africa/Gaborone", "CAT", None],
    ["Africa/Harare", "CAT", None],
    ["Africa/Johannesburg", "SAST", None],
    ["Africa/Juba", "EAT", None],
    ["Africa/Kampala", "EAT", None],
    ["Africa/Khartoum", "EAT", None],
    ["Africa/Kigali", "CAT", None],
    ["Africa/Kinshasa", "WAT", None],
    ["Africa/Lagos", "WAT", None],
    ["Africa/Libreville", "WAT", None],
    ["Africa/Lome", "GMT", None],
    ["Africa/Luanda", "WAT", None],
    ["Africa/Lubumbashi", "CAT", None],
    ["Africa/Lusaka", "CAT", None],
    ["Africa/Malabo", "WAT", None],
    ["Africa/Maputo", "CAT", None],
    ["Africa/Maseru", "SAST", None],
    ["Africa/Mbabane", "SAST", None],
    ["Africa/Mogadishu", "EAT", None],
    ["Africa/Monrovia", "GMT", None],
    ["Africa/Nairobi", "EAT", None],
    ["Africa/Ndjamena", "WAT", None],
    ["Africa/Niamey", "WAT", None],
    ["Africa/Nouakchott", "GMT", None],
    ["Africa/Ouagadougou", "GMT", None],
    ["Africa/Porto-Novo", "WAT", None],
    ["Africa/Porto_Novo", "WAT", None],
    ["Africa/Sao_Tome", "GMT", None],
    ["Africa/Timbuktu", "GMT", None],
    ["Africa/Tripoli", "EET", None],
    ["Africa/Tunis", "CET", None],
    ["Africa/Windhoek", "WAT", "WAST"],
    ["America/Adak", "HST", "HDT"],
    ["America/Anchorage", "AKST", "AKDT"],
    ["America/Anguilla", "AST", None],
    ["America/Antigua", "AST", None],
    ["America/Araguaina", "BRT", None],
    ["America/Argentina/Buenos_Aires", "ART", None],
    ["America/Argentina/Catamarca", "ART", None],
    ["America/Argentina/ComodRivadavia", "ART", None],
    ["America/Argentina/Cordoba", "ART", None],
    ["America/Argentina/Jujuy", "ART", None],
    ["America/Argentina/La_Rioja", "ART", None],
    ["America/Argentina/Mendoza", "ART", None],
    ["America/Argentina/Rio_Gallegos", "ART", None],
    ["America/Argentina/Salta", "ART", None],
    ["America/Argentina/San_Juan", "ART", None],
    ["America/Argentina/San_Luis", "ART", None],
    ["America/Argentina/Tucuman", "ART", None],
    ["America/Argentina/Ushuaia", "ART", None],
    ["America/Aruba", "AST", None],
    ["America/Asuncion", "PYT", "PYST"],
    ["America/Atikokan", "EST", None],
    ["America/Atka", "HST", "HDT"],
    ["America/Bahia", "BRT", None],
    ["America/Bahia_Banderas", "CST", "CDT"],
    ["America/Barbados", "AST", None],
    ["America/Belem", "BRT", None],
    ["America/Belize", "CST", None],
    ["America/Beulah", "CST", "CDT"],
    ["America/Blanc-Sablon", "AST", None],
    ["America/Blanc_Sablon", "AST", None],
    ["America/Boa_Vista", "AMT", None],
    ["America/Bogota", "COT", None],
    ["America/Boise", "MST", "MDT"],
    ["America/Buenos_Aires", "ART", None],
    ["America/Cambridge_Bay", "MST", "MDT"],
    ["America/Campo_Grande", "AMT", "AMST"],
    ["America/Cancun", "EST", None],
    ["America/Caracas", "VET", None],
    ["America/Catamarca", "ART", None],
    ["America/Cayenne", "GFT", None],
    ["America/Cayman", "EST", None],
    ["America/Center", "CST", "CDT"],
    ["America/Chicago", "CST", "CDT"],
    ["America/Chihuahua", "MST", "MDT"],
    ["America/ComodRivadavia", "ART", None],
    ["America/Coral_Harbour", "EST", None],
    ["America/Cordoba", "ART", None],
    ["America/Costa_Rica", "CST", None],
    ["America/Creston", "MST", None],
    ["America/Cuiaba", "AMT", "AMST"],
    ["America/Curacao", "AST", None],
    ["America/Danmarkshavn", "GMT", None],
    ["America/Dawson", "PST", "PDT"],
    ["America/Dawson_Creek", "MST", None],
    ["America/Denver", "MST", "MDT"],
    ["America/Detroit", "EST", "EDT"],
    ["America/Dominica", "AST", None],
    ["America/Edmonton", "MST", "MDT"],
    ["America/Eirunepe", "ACT", None],
    ["America/El_Salvador", "CST", None],
    ["America/Ensenada", "PST", "PDT"],
    ["America/Fortaleza", "BRT", None],
    ["America/Fort_Wayne", "EST", "EDT"],
    ["America/Glace_Bay", "AST", "ADT"],
    ["America/Godthab", "WGT", "WGST"],
    ["America/Goose_Bay", "AST", "ADT"],
    ["America/Grand_Turk", "AST", None],
    ["America/Grenada", "AST", None],
    ["America/Guadeloupe", "AST", None],
    ["America/Guatemala", "CST", None],
    ["America/Guayaquil", "ECT", None],
    ["America/Guyana", "GYT", None],
    ["America/Halifax", "AST", "ADT"],
    ["America/Havana", "CST", "CDT"],
    ["America/Hermosillo", "MST", None],
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
    ["America/Jamaica", "EST", None],
    ["America/Jujuy", "ART", None],
    ["America/Juneau", "AKST", "AKDT"],
    ["America/Kentucky/Louisville", "EST", "EDT"],
    ["America/Kentucky/Monticello", "EST", "EDT"],
    ["America/Knox", "CST", "CDT"],
    ["America/Knox_IN", "CST", "CDT"],
    ["America/Kralendijk", "AST", None],
    ["America/La_Paz", "BOT", None],
    ["America/La_Rioja", "ART", None],
    ["America/Lima", "PET", None],
    ["America/Los_Angeles", "PST", "PDT"],
    ["America/Louisville", "EST", "EDT"],
    ["America/Lower_Princes", "AST", None],
    ["America/Maceio", "BRT", None],
    ["America/Managua", "CST", None],
    ["America/Manaus", "AMT", None],
    ["America/Marengo", "EST", "EDT"],
    ["America/Marigot", "AST", None],
    ["America/Martinique", "AST", None],
    ["America/Matamoros", "CST", "CDT"],
    ["America/Mazatlan", "MST", "MDT"],
    ["America/Mendoza", "ART", None],
    ["America/Menominee", "CST", "CDT"],
    ["America/Merida", "CST", "CDT"],
    ["America/Metlakatla", "AKST", "AKDT"],
    ["America/Mexico_City", "CST", "CDT"],
    ["America/Miquelon", "PMST", "PMDT"],
    ["America/Moncton", "AST", "ADT"],
    ["America/Monterrey", "CST", "CDT"],
    ["America/Montevideo", "UYT", None],
    ["America/Monticello", "EST", "EDT"],
    ["America/Montreal", "EST", "EDT"],
    ["America/Montserrat", "AST", None],
    ["America/Nassau", "EST", "EDT"],
    ["America/New_Salem", "CST", "CDT"],
    ["America/New_York", "EST", "EDT"],
    ["America/Nipigon", "EST", "EDT"],
    ["America/Nome", "AKST", "AKDT"],
    ["America/Noronha", "FNT", None],
    ["America/North_Dakota/Beulah", "CST", "CDT"],
    ["America/North_Dakota/Center", "CST", "CDT"],
    ["America/North_Dakota/New_Salem", "CST", "CDT"],
    ["America/Ojinaga", "MST", "MDT"],
    ["America/Panama", "EST", None],
    ["America/Pangnirtung", "EST", "EDT"],
    ["America/Paramaribo", "SRT", None],
    ["America/Petersburg", "EST", "EDT"],
    ["America/Phoenix", "MST", None],
    ["America/Port-au-Prince", "EST", None],
    ["America/Porto_Acre", "ACT", None],
    ["America/Porto_Velho", "AMT", None],
    ["America/Port_au_Prince", "EST", None],
    ["America/Port_of_Spain", "AST", None],
    ["America/Puerto_Rico", "AST", None],
    ["America/Rainy_River", "CST", "CDT"],
    ["America/Rankin_Inlet", "CST", "CDT"],
    ["America/Recife", "BRT", None],
    ["America/Regina", "CST", None],
    ["America/Resolute", "CST", "CDT"],
    ["America/Rio_Branco", "ACT", None],
    ["America/Rio_Gallegos", "ART", None],
    ["America/Rosario", "ART", None],
    ["America/Salta", "ART", None],
    ["America/Santarem", "BRT", None],
    ["America/Santa_Isabel", "PST", "PDT"],
    ["America/Santiago", "CLT", "CLST"],
    ["America/Santo_Domingo", "AST", None],
    ["America/San_Juan", "ART", None],
    ["America/San_Luis", "ART", None],
    ["America/Sao_Paulo", "BRT", "BRST"],
    ["America/Scoresbysund", "EGT", "EGST"],
    ["America/Shiprock", "MST", "MDT"],
    ["America/Sitka", "AKST", "AKDT"],
    ["America/St_Barthelemy", "AST", None],
    ["America/St_Johns", "NST", "NDT"],
    ["America/St_Kitts", "AST", None],
    ["America/St_Lucia", "AST", None],
    ["America/St_Thomas", "AST", None],
    ["America/St_Vincent", "AST", None],
    ["America/Swift_Current", "CST", None],
    ["America/Tegucigalpa", "CST", None],
    ["America/Tell_City", "CST", "CDT"],
    ["America/Thule", "AST", "ADT"],
    ["America/Thunder_Bay", "EST", "EDT"],
    ["America/Tijuana", "PST", "PDT"],
    ["America/Toronto", "EST", "EDT"],
    ["America/Tortola", "AST", None],
    ["America/Tucuman", "ART", None],
    ["America/Ushuaia", "ART", None],
    ["America/Vancouver", "PST", "PDT"],
    ["America/Vevay", "EST", "EDT"],
    ["America/Vincennes", "EST", "EDT"],
    ["America/Virgin", "AST", None],
    ["America/Whitehorse", "PST", "PDT"],
    ["America/Winamac", "EST", "EDT"],
    ["America/Winnipeg", "CST", "CDT"],
    ["America/Yakutat", "AKST", "AKDT"],
    ["America/Yellowknife", "MST", "MDT"],
    ["Antarctica/Casey", "AWST", None],
    ["Antarctica/Davis", "DAVT", None],
    ["Antarctica/DumontDUrville", "DDUT", None],
    ["Antarctica/Macquarie", "MIST", None],
    ["Antarctica/Mawson", "MAWT", None],
    ["Antarctica/McMurdo", "NZST", "NZDT"],
    ["Antarctica/Palmer", "CLT", "CLST"],
    ["Antarctica/Rothera", "ROTT", None],
    ["Antarctica/South_Pole", "NZST", "NZDT"],
    ["Antarctica/Syowa", "SYOT", None],
    ["Antarctica/Troll", "UTC", "CEST"],
    ["Antarctica/Vostok", "VOST", None],
    ["Arctic/Longyearbyen", "CET", "CEST"],
    ["Asia/Aden", "AST", None],
    ["Asia/Almaty", "ALMT", None],
    ["Asia/Amman", "EET", "EEST"],
    ["Asia/Anadyr", "ANAT", None],
    ["Asia/Aqtau", "AQTT", None],
    ["Asia/Aqtobe", "AQTT", None],
    ["Asia/Ashgabat", "TMT", None],
    ["Asia/Ashkhabad", "TMT", None],
    ["Asia/Baghdad", "AST", None],
    ["Asia/Bahrain", "AST", None],
    ["Asia/Baku", "AZT", None],
    ["Asia/Bangkok", "ICT", None],
    ["Asia/Beirut", "EET", "EEST"],
    ["Asia/Bishkek", "KGT", None],
    ["Asia/Brunei", "BNT", None],
    ["Asia/Calcutta", "IST", None],
    ["Asia/Chita", "YAKT", None],
    ["Asia/Choibalsan", "CHOT", "CHOST"],
    ["Asia/Chongqing", "CST", None],
    ["Asia/Chungking", "CST", None],
    ["Asia/Colombo", "IST", None],
    ["Asia/Dacca", "BDT", None],
    ["Asia/Damascus", "EET", "EEST"],
    ["Asia/Dhaka", "BDT", None],
    ["Asia/Dili", "TLT", None],
    ["Asia/Dubai", "GST", None],
    ["Asia/Dushanbe", "TJT", None],
    ["Asia/Gaza", "EET", "EEST"],
    ["Asia/Harbin", "CST", None],
    ["Asia/Hebron", "EET", "EEST"],
    ["Asia/Hong_Kong", "HKT", None],
    ["Asia/Hovd", "HOVT", "HOVST"],
    ["Asia/Ho_Chi_Minh", "ICT", None],
    ["Asia/Irkutsk", "IRKT", None],
    ["Asia/Istanbul", "EET", "EEST"],
    ["Asia/Jakarta", "WIB", None],
    ["Asia/Jayapura", "WIT", None],
    ["Asia/Jerusalem", "IST", "IDT"],
    ["Asia/Kabul", "AFT", None],
    ["Asia/Kamchatka", "PETT", None],
    ["Asia/Karachi", "PKT", None],
    ["Asia/Kashgar", "XJT", None],
    ["Asia/Kathmandu", "NPT", None],
    ["Asia/Katmandu", "NPT", None],
    ["Asia/Khandyga", "YAKT", None],
    ["Asia/Kolkata", "IST", None],
    ["Asia/Krasnoyarsk", "KRAT", None],
    ["Asia/Kuala_Lumpur", "MYT", None],
    ["Asia/Kuching", "MYT", None],
    ["Asia/Kuwait", "AST", None],
    ["Asia/Macao", "CST", None],
    ["Asia/Macau", "CST", None],
    ["Asia/Magadan", "MAGT", None],
    ["Asia/Makassar", "WITA", None],
    ["Asia/Manila", "PHT", None],
    ["Asia/Muscat", "GST", None],
    ["Asia/Nicosia", "EET", "EEST"],
    ["Asia/Novokuznetsk", "KRAT", None],
    ["Asia/Novosibirsk", "NOVT", None],
    ["Asia/Omsk", "OMST", None],
    ["Asia/Oral", "ORAT", None],
    ["Asia/Phnom_Penh", "ICT", None],
    ["Asia/Pontianak", "WIB", None],
    ["Asia/Pyongyang", "KST", None],
    ["Asia/Qatar", "AST", None],
    ["Asia/Qyzylorda", "QYZT", None],
    ["Asia/Rangoon", "MMT", None],
    ["Asia/Riyadh", "AST", None],
    ["Asia/Saigon", "ICT", None],
    ["Asia/Sakhalin", "SAKT", None],
    ["Asia/Samarkand", "UZT", None],
    ["Asia/Seoul", "KST", None],
    ["Asia/Shanghai", "CST", None],
    ["Asia/Singapore", "SGT", None],
    ["Asia/Srednekolymsk", "SRET", None],
    ["Asia/Taipei", "CST", None],
    ["Asia/Tashkent", "UZT", None],
    ["Asia/Tbilisi", "GET", None],
    ["Asia/Tehran", "IRST", "IRDT"],
    ["Asia/Tel_Aviv", "IST", "IDT"],
    ["Asia/Thimbu", "BTT", None],
    ["Asia/Thimphu", "BTT", None],
    ["Asia/Tokyo", "JST", None],
    ["Asia/Ujung_Pandang", "WITA", None],
    ["Asia/Ulaanbaatar", "ULAT", "ULAST"],
    ["Asia/Ulan_Bator", "ULAT", "ULAST"],
    ["Asia/Urumqi", "XJT", None],
    ["Asia/Ust-Nera", "VLAT", None],
    ["Asia/Ust_Nera", "VLAT", None],
    ["Asia/Vientiane", "ICT", None],
    ["Asia/Vladivostok", "VLAT", None],
    ["Asia/Yakutsk", "YAKT", None],
    ["Asia/Yekaterinburg", "YEKT", None],
    ["Asia/Yerevan", "AMT", None],
    ["Atlantic/Azores", "AZOT", "AZOST"],
    ["Atlantic/Bermuda", "AST", "ADT"],
    ["Atlantic/Canary", "WET", "WEST"],
    ["Atlantic/Cape_Verde", "CVT", None],
    ["Atlantic/Faeroe", "WET", "WEST"],
    ["Atlantic/Faroe", "WET", "WEST"],
    ["Atlantic/Jan_Mayen", "CET", "CEST"],
    ["Atlantic/Madeira", "WET", "WEST"],
    ["Atlantic/Reykjavik", "GMT", None],
    ["Atlantic/South_Georgia", "GST", None],
    ["Atlantic/Stanley", "FKST", None],
    ["Atlantic/St_Helena", "GMT", None],
    ["Australia/ACT", "AEST", "AEDT"],
    ["Australia/Adelaide", "ACST", "ACDT"],
    ["Australia/Brisbane", "AEST", None],
    ["Australia/Broken_Hill", "ACST", "ACDT"],
    ["Australia/Canberra", "AEST", "AEDT"],
    ["Australia/Currie", "AEST", "AEDT"],
    ["Australia/Darwin", "ACST", None],
    ["Australia/Eucla", "ACWST", None],
    ["Australia/Hobart", "AEST", "AEDT"],
    ["Australia/LHI", "LHST", "LHDT"],
    ["Australia/Lindeman", "AEST", None],
    ["Australia/Lord_Howe", "LHST", "LHDT"],
    ["Australia/Melbourne", "AEST", "AEDT"],
    ["Australia/North", "ACST", None],
    ["Australia/NSW", "AEST", "AEDT"],
    ["Australia/Perth", "AWST", None],
    ["Australia/Queensland", "AEST", None],
    ["Australia/South", "ACST", "ACDT"],
    ["Australia/Sydney", "AEST", "AEDT"],
    ["Australia/Tasmania", "AEST", "AEDT"],
    ["Australia/Victoria", "AEST", "AEDT"],
    ["Australia/West", "AWST", None],
    ["Australia/Yancowinna", "ACST", "ACDT"],
    ["Brazil/Acre", "ACT", None],
    ["Brazil/DeNoronha", "FNT", None],
    ["Brazil/East", "BRT", "BRST"],
    ["Brazil/West", "AMT", None],
    ["Canada/Atlantic", "AST", "ADT"],
    ["Canada/Central", "CST", "CDT"],
    ["Canada/East-Saskatchewan", "CST", None],
    ["Canada/Eastern", "EST", "EDT"],
    ["Canada/East_Saskatchewan", "CST", None],
    ["Canada/Mountain", "MST", "MDT"],
    ["Canada/Newfoundland", "NST", "NDT"],
    ["Canada/Pacific", "PST", "PDT"],
    ["Canada/Saskatchewan", "CST", None],
    ["Canada/Yukon", "PST", "PDT"],
    ["Chile/Continental", "CLT", "CLST"],
    ["Chile/EasterIsland", "EAST", "EASST"],
    ["Etc/GMT", "GMT", None],
    ["Etc/Greenwich", "GMT", None],
    ["Etc/UCT", "UCT", None],
    ["Etc/Universal", "UTC", None],
    ["Etc/UTC", "UTC", None],
    ["Etc/Zulu", "UTC", None],
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
    ["Europe/Kaliningrad", "EET", None],
    ["Europe/Kiev", "EET", "EEST"],
    ["Europe/Lisbon", "WET", "WEST"],
    ["Europe/Ljubljana", "CET", "CEST"],
    ["Europe/London", "GMT", "BST"],
    ["Europe/Luxembourg", "CET", "CEST"],
    ["Europe/Madrid", "CET", "CEST"],
    ["Europe/Malta", "CET", "CEST"],
    ["Europe/Mariehamn", "EET", "EEST"],
    ["Europe/Minsk", "MSK", None],
    ["Europe/Monaco", "CET", "CEST"],
    ["Europe/Moscow", "MSK", None],
    ["Europe/Nicosia", "EET", "EEST"],
    ["Europe/Oslo", "CET", "CEST"],
    ["Europe/Paris", "CET", "CEST"],
    ["Europe/Podgorica", "CET", "CEST"],
    ["Europe/Prague", "CET", "CEST"],
    ["Europe/Riga", "EET", "EEST"],
    ["Europe/Rome", "CET", "CEST"],
    ["Europe/Samara", "SAMT", None],
    ["Europe/San_Marino", "CET", "CEST"],
    ["Europe/Sarajevo", "CET", "CEST"],
    ["Europe/Simferopol", "MSK", None],
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
    ["Europe/Volgograd", "MSK", None],
    ["Europe/Warsaw", "CET", "CEST"],
    ["Europe/Zagreb", "CET", "CEST"],
    ["Europe/Zaporozhye", "EET", "EEST"],
    ["Europe/Zurich", "CET", "CEST"],
    ["Indian/Antananarivo", "EAT", None],
    ["Indian/Chagos", "IOT", None],
    ["Indian/Christmas", "CXT", None],
    ["Indian/Cocos", "CCT", None],
    ["Indian/Comoro", "EAT", None],
    ["Indian/Kerguelen", "TFT", None],
    ["Indian/Mahe", "SCT", None],
    ["Indian/Maldives", "MVT", None],
    ["Indian/Mauritius", "MUT", None],
    ["Indian/Mayotte", "EAT", None],
    ["Indian/Reunion", "RET", None],
    ["Mexico/BajaNorte", "PST", "PDT"],
    ["Mexico/BajaSur", "MST", "MDT"],
    ["Mexico/General", "CST", "CDT"],
    ["Pacific/Apia", "WSST", "WSDT"],
    ["Pacific/Auckland", "NZST", "NZDT"],
    ["Pacific/Chatham", "CHAST", "CHADT"],
    ["Pacific/Chuuk", "CHUT", None],
    ["Pacific/Easter", "EAST", "EASST"],
    ["Pacific/Efate", "VUT", None],
    ["Pacific/Enderbury", "PHOT", None],
    ["Pacific/Fakaofo", "TKT", None],
    ["Pacific/Fiji", "FJT", "FJST"],
    ["Pacific/Funafuti", "TVT", None],
    ["Pacific/Galapagos", "GALT", None],
    ["Pacific/Gambier", "GAMT", None],
    ["Pacific/Guadalcanal", "SBT", None],
    ["Pacific/Guam", "ChST", None],
    ["Pacific/Honolulu", "HST", None],
    ["Pacific/Johnston", "HST", None],
    ["Pacific/Kiritimati", "LINT", None],
    ["Pacific/Kosrae", "KOST", None],
    ["Pacific/Kwajalein", "MHT", None],
    ["Pacific/Majuro", "MHT", None],
    ["Pacific/Marquesas", "MART", None],
    ["Pacific/Midway", "SST", None],
    ["Pacific/Nauru", "NRT", None],
    ["Pacific/Niue", "NUT", None],
    ["Pacific/Norfolk", "NFT", None],
    ["Pacific/Noumea", "NCT", None],
    ["Pacific/Pago_Pago", "SST", None],
    ["Pacific/Palau", "PWT", None],
    ["Pacific/Pitcairn", "PST", None],
    ["Pacific/Pohnpei", "PONT", None],
    ["Pacific/Ponape", "PONT", None],
    ["Pacific/Port_Moresby", "PGT", None],
    ["Pacific/Rarotonga", "CKT", None],
    ["Pacific/Saipan", "ChST", None],
    ["Pacific/Samoa", "SST", None],
    ["Pacific/Tahiti", "TAHT", None],
    ["Pacific/Tarawa", "GILT", None],
    ["Pacific/Tongatapu", "TOT", None],
    ["Pacific/Truk", "CHUT", None],
    ["Pacific/Wake", "WAKT", None],
    ["Pacific/Wallis", "WFT", None],
    ["Pacific/Yap", "CHUT", None],
];

TZDB = {}
DSTZDB = {}
for row in tzNamesDB:
    name = row[0].upper()
    TZDB[name] = row[1]
    DSTZDB[name] = row[2]

#-----------------------------------------------------------------------------#
#                                                                             #
#   Function        http REST functions                                       #
#                                                                             #
#   Description     Get and post HTTP requests, using the requests library    #
#                                                                             #
#   Arguments                                                                 #
#                                                                             #
#   Returns                                                                   #
#                                                                             #
#   Notes           See the requests library documentation:                   #
#                   http://docs.python-requests.org/en/latest/user/advanced/  #
#                                                                             #
#   History                                                                   #
#    2017-11-24 JFL Created these routines.                                   #
#                                                                             #
#-----------------------------------------------------------------------------#

def ExecRest(url, data=None, options = defaultOptions):
    kwargs = {} # Optional named args we may want to pass to the requests library
    # http://docs.python-requests.org/en/latest/user/advanced/#ssl-cert-verification
    if 'verify' in options: kwargs['verify'] = options['verify']
    # http://docs.python-requests.org/en/latest/user/advanced/#timeouts
    if 'timeout' in options: kwargs['timeout'] = options['timeout']
    if options['debug'] and len(kwargs): print('# Request options: %s' % json.dumps(kwargs))
    try:
        if data:
            response = requests.post(url, data, **kwargs)
        else:
            response = requests.get(url, **kwargs)
    except requests.ConnectionError as e:
        raise FatalError("A Connection error occurred")
    except requests.HTTPError as e:
        raise FatalError("An HTTP error occurred")
    except requests.URLRequired as e:
        raise FatalError("Invalid URL: %s" % url)
    except requests.TooManyRedirects as e:
        raise FatalError("Too many redirects")

    if options['debug']: print('# HTTP code %s: %s' % (response.status_code, response.reason))
    if response.status_code != 200:
        raise FatalError("HTTP error %d. %s" % (response.status_code, response.reason))

    return response.text

##
# @desc  Get the output from a REST API
# @param string url     The request url
# @param array  options overriding script defaults. Ex: ["debug"=1]
# @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) error
# @return The REST string returned by the server
#
def GetRest(url, options = defaultOptions):
    return ExecRest(url, None, options)

##
# @desc  Post arguments, and return the output from a REST API
# @param string url The request url
# @param string data The post data
# @param array  options overriding script defaults. Ex: ["debug"=1]
# @throws FatalError Message describing an XMLHttpRequest (connection) or HTTP (web server) error
# @return The REST string returned by the server
#
def PostRest(url, data=None, options = defaultOptions):
    return ExecRest(url, data, options)

#-----------------------------------------------------------------------------#
#                                                                             #
#   Function        main                                                      #
#                                                                             #
#   Description     Process command-line arguments                            #
#                                                                             #
#   Arguments                                                                 #
#                                                                             #
#   Returns                                                                   #
#                                                                             #
#   Notes                                                                     #
#                                                                             #
#   History                                                                   #
#    2017-10-31 JFL Created these routine.                                    #
#                                                                             #
#-----------------------------------------------------------------------------#

# Execute the rest of this file only when it's invoked as a standalone script
if __name__ == '__main__':

    # Display a help screen
    if os.name == 'nt':
        systemProfile = "%windir%\location.inf"
        userProfile = "%USERPROFILE%\location.inf"
        root = "Administrator"
    else: # Unix
        systemProfile = "/etc/location.conf"
        userProfile = "~/.location"
        root = "root"

    def usage():
        global script
        print('''\
%s - Get the system location based on its IP address

Usage: %s [OPTIONS] [SERVER|IP]

Options:
  -?|-h     Display this help and exit
  -d        Debug mode. Display internal infos about how things work
  -j        Display the freegeoip.app JSON response
  -s        Save the system location data into file %s
            (Recommended for today/sunrise/sunset. Must be running as %s.)
  -u        Save the user location data into file %s
            (Alternative for today/sunrise/sunset, when not running as %s.)
  -v        Verbose mode. Display more infos about commands and results
  -V        Display this script version and exit
  -x        Display the freegeoip.app XML response
''' % (script, script, systemProfile, root, userProfile, root))

    # Test if an argument is a switch or not
    def isSwitch(arg):
        # Switches begin by a "-". (Which is the standard for Unix shells, but not for Windows')
        # Exception: By convention, the file name "-" means stdin or stdout.
        return ((arg[0:1] == "-") and (arg != "-"))

    # Process command-line arguments, and run the requested commands
    def main(argc, argv):
        global script
        global defaultOptions
        options = defaultOptions
        props = {}              # Properties used for selecting files to list
        action = "list"
        api = "json"
        host = ""
        noExec = False

        i = 1
        while i < argc:
            arg = argv[i]
            i += 1
            if (isSwitch(arg)): # This is an option
                opt = arg[1:]
                if opt == 'd':      # Debug mode
                    options["debug"] += 1
                    continue
                if opt == 'h' or opt == '-help' or opt == '?': # Display a help screen and exit
                    usage()
                    return 0
                if opt == 'j':      # Dump the raw json data
                    api = "json"
                    action = "dump"
                    continue
                if opt == 's':      # Save the /etc/location.conf configuration file
                    api = "json"
                    action = "system"
                    continue
                if opt == 'u':      # Save the ~/.location configuration file
                    api = "json"
                    action = "user"
                    continue
                if opt == 'v':      # Verbose
                    options["verbose"] = True
                    continue
                if opt == 'V' or opt == '-version':
                    if options["verbose"]:
                        print("Python %s" % sys.version)
                        sys.stdout.write("%s " % script)
                    print(VERSION)
                    return 0
                if opt == 'x':      # Dump the raw xml data
                    api = "xml"
                    action = "dump"
                    continue
                if opt == 'X':      # No-exec mode
                    noExec = True
                    continue
                raise FatalError("Invalid option: " + arg)
            # Then process normal arguments
            if host == "":
                host = arg
                continue
            raise FatalError("Invalid argument: " + arg)

        # The HTTP requests library is often not installed by default
        # Loading it here allows getting help even if it's not installed yet
        try:
            global requests
            import requests
        except ImportError:
            raise FatalError("Cannot find the requests library. Try running 'pip install requests'.")

        urlFreeGeoIP = "https://freegeoip.app" # Application server
        url = "%s/%s/%s" % (urlFreeGeoIP, api, host)
        if options["verbose"] or options["debug"]:
            print("# GET %s" % url)

        reply = GetRest(url, options)

        # Merge the following two actions into a single "save" action
        if action == "system":
            if os.name == 'nt':
                filename = os.environ['windir'] + "\\location.inf"
            else:
                filename = "/etc/location.conf"
            action = "save"
        elif action == "user":
            if os.name == 'nt':
                filename = os.environ['USERPROFILE'] + "\\location.inf"
            else:
                filename = os.environ['HOME'] + "/.location"
            action = "save"

        # Merge the following two actions into a single "list" action
        if action == "list":
            hFile = sys.stdout
        elif action == "save":
            print("Writing location data to \"%s\"" % filename)
            if not noExec:
                hFile = open(filename, 'w')
            else:
                hFile = sys.stdout
            action = "list"

        if action == "dump":
            hFile = sys.stdout
            hFile.write(reply)
        elif action == "list":
            params = json.loads(reply)
            for i, key in enumerate(params):
                value = params[key]
                key = key.upper().replace('_', '')
                hFile.write("%s = %s\n" % (key, value))
                if key == "TIMEZONE":
                    tzNAME = value.upper()
                    try:
                        global TZDB, DSTZDB
                        hFile.write("TZABBR = %s\n" % TZDB[tzNAME])
                        hFile.write("DSTZABBR = %s\n" % DSTZDB[tzNAME])
                    except e:
                        pass

        if hFile != sys.stdout:
            hFile.close()

        return 0

    # Top level code, executed when running this module as a standalone script
    try:
        exitCode = main(len(sys.argv), sys.argv)
    except FatalError as e: # Our own "controlled" errors
        sys.stderr.write("Error: %s\n" % e.args[0])
        exitCode = 1
    except Exception as e: # Out-of-control failures
        # Do not raise the exception, but just display the traceback
        sys.stderr.write(traceback.format_exc())
        exitCode = 2
    sys.exit(exitCode)
