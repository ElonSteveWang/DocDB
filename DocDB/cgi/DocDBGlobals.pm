# DB settings
$db_name   = "BTeVDocDB";
$db_host   = "fnsimu1.fnal.gov";
$db_rwuser = "docdbrw";
$db_rwpass = "hall1burt0n";
$db_rouser = "docdbro";
$db_ropass = "abg3n1x";

# Root directories and URLs

$file_root   = "/www/html/DocDB/";    
$script_root = "/www/cgi-bin/DocDB/"; 
$web_root    = "http://www-btev.fnal.gov/DocDB/";
$cgi_root    = "http://www-btev.fnal.gov/cgi-bin/DocDB/";
$SSIDirectory = "/www/html/includes/";

# Shell Commands

$Wget   = "/home/btev1/ewv/bin/wget -O - --quiet ";
$Tar    = "/fnal/ups/prod/gtools/v2_4/bin/gtar ";
$Unzip  = "/usr/local/bin/unzip -q ";

# Useful stuff

%ReverseFullMonth = (January => 1,  February => 2,  March     => 3,
                     April   => 4,  May      => 5,  June      => 6,
                     July    => 7,  August   => 8,  September => 9,
                     October => 10, November => 11, December  => 12);

%ReverseAbrvMonth = (Jan => 1,  Feb => 2,  Mar => 3,
                     Apr => 4,  May => 5,  Jun => 6,
                     Jul => 7,  Aug => 8,  Sep => 9,
                     Oct => 10, Nov => 11, Dec => 12);

@AbrvMonths = ("Jan","Feb","Mar","Apr","May","Jun",
               "Jul","Aug","Sep","Oct","Nov","Dec");

@FullMonths = ("January","February","March","April",
               "May","June","July","August",
               "September","October","November","December");

# Other Globals

$remote_user = $ENV{REMOTE_USER};
$DBWebMasterEmail = "btev-docdb\@fnal.gov";
$DBWebMasterName  = "BTeV Document Database Administrators";
$Administrator    = "docdbadm";
$AuthUserFile     = "/www/conf/www-btev/.htpasswd";

# Override settings in this file for the test DB 
# and the publicly accessible version

if (-e "PublicGlobals.pm") {
  require "PublicGlobals.pm";
}  

if (-e "TestGlobals.pm") {
  require "TestGlobals.pm";
}  

# Special files (here because they use values from above)

$htaccess     = ".htaccess";
$help_file    = $script_root."docdb.hlp";

# CGI Scripts

$MainPage           = $cgi_root."DocumentDatabase";
$ProcessDocumentAdd = $cgi_root."ProcessDocumentAdd";
$DocumentAddForm    = $cgi_root."DocumentAddForm";
$ShowDocument       = $cgi_root."ShowDocument";
$ListDocuments      = $cgi_root."ListDocuments";

$TopicAddForm       = $cgi_root."TopicAddForm";
$AuthorAddForm      = $cgi_root."AuthorAddForm";

$ListByAuthor       = $cgi_root."ListByAuthor";
$ListByTopic        = $cgi_root."ListByTopic";
$ListByType         = $cgi_root."ListByType";
$LastModified       = $cgi_root."LastModified";

$ListAuthors        = $cgi_root."ListAuthors";
$ListTopics         = $cgi_root."ListTopics";
$ListTypes          = $cgi_root."ListTypes";

$AddFiles           = $cgi_root."AddFiles";
$AddFilesForm       = $cgi_root."AddFilesForm";

$HelpFile           = $web_root."Help/DocDB_Help.shtml";

1;
