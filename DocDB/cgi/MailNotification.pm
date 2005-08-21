# Copyright 2001-2005 Eric Vaandering, Lynn Garren, Adam Bryant

#    This file is part of DocDB.

#    DocDB is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License 
#    as published by the Free Software Foundation.

#    DocDB is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DocDB; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

sub MailNotices (%) {

  unless ($MailInstalled) {
    return;
  }  

  require Mail::Send;
  require Mail::Mailer;

  require "RevisionSQL.pm";
  require "NotificationSQL.pm";
  require "ResponseElements.pm";
  require "Utilities.pm";
  require "Security.pm";
  
  my (%Params) = @_;

  my $DocRevID     =   $Params{-docrevid};
  my $Type         =   $Params{-type}      || "update";
  my @EmailUserIDs = @{$Params{-emailids}};
  
  &FetchDocRevisionByID($DocRevID);
  my $DocumentID = $DocRevisions{$DocRevID}{DOCID};
  my $Version    = $DocRevisions{$DocRevID}{Version};
  
# Figure out who cares 

  my @Addressees = ();
  if ($Type eq "update") {
    @Addressees = &UsersToNotify($DocRevID,"immediate");
  } elsif ($Type eq "signature") {
    foreach my $EmailUserID (@EmailUserIDs) {# Extract emails
      &FetchEmailUser($EmailUserID);
      push @Addressees,$EmailUser{$EmailUserID}{EmailAddress};
    }
  } elsif ($Type eq "approved") { 
    @Addressees = &UsersToNotify($DocRevID,"immediate");
    my %EmailUsers = ();
    my @SignoffIDs = &GetAllSignoffsByDocRevID($DocRevID);
    foreach my $SignoffID (@SignoffIDs) {
      my @SignatureIDs = &GetSignatures($SignoffID);
      foreach my $SignatureID (@SignatureIDs) {
        my $EmailUserID = $Signatures{$SignatureID}{EmailUserID};
        &FetchEmailUser($EmailUserID);
        push @Addressees,$EmailUser{$EmailUserID}{EmailAddress};
      }  
    }  
  } 
  
  @Addressees = &Unique(@Addressees);
  
# If anyone, open the mailer

  if (@Addressees) {
    $Mailer = new Mail::Mailer 'smtp', Server => $MailServer;
#    $Mailer = new Mail::Mailer 'test', Server => $MailServer;
    my %Headers = ();

    my $FullID = &FullDocumentID($DocRevisions{$DocRevID}{DOCID},$DocRevisions{$DocRevID}{VERSION});
    my $Title  = $DocRevisions{$DocRevID}{Title};

    my ($Subject,$Message,$Feedback);
    
    if ($Type eq "update") {
      $Subject  = "$FullID: $Title";
      $Message  = "The following document was added or changed ".
                  "in the $Project Document Database:\n\n";
      $Feedback = "<b>E-mail sent to: </b>";           
    } elsif ($Type eq "signature") {
      $Subject  = "Ready for signature: $FullID: $Title";
      $Message  = "The following document ".
                  "in the $Project Document Database ".
                  "is ready for your signature:\n".
                  "(Note that you may not be able to sign if you share ".
                  "signature authority with someone who has already signed.)\n\n";
      $Feedback = "<b>Signature(s) requested from: </b>";           
    } elsif ($Type eq "approved") {
      $Subject  = "Approved: $FullID: $Title";
      $Message  = "The following document ".
                  "in the $Project Document Database ".
                  "has been approved (received all necessary signatures).\n\n";
      $Feedback = "<b>Approval notification sent to: </b>";           
    }  

    $Headers{To} = \@Addressees;
    $Headers{From} = "$Project Document Database <$DBWebMasterEmail>";
    $Headers{Subject} = $Subject;

    $Mailer -> open(\%Headers);    # Start mail with headers
    print $Mailer $Message;
    &RevisionMailBody($DocRevID);  # Write the body
    $Mailer -> close;              # Complete the message and send it
    my $Addressees = join ', ',@Addressees;
    $Addressees =~ s/\&/\&amp\;/g;
    $Addressees =~ s/</\&lt\;/g;
    $Addressees =~ s/>/\&gt\;/g;
    
    print $Feedback,$Addressees,"<p>";
  }  
}

sub RevisionMailBody ($) {
  require "RevisionSQL.pm";
  require "ResponseElements.pm";
  require "AuthorSQL.pm";
  require "Sorts.pm";

  my ($DocRevID) = @_;
  &FetchDocRevisionByID($DocRevID);
  
  my $Title  = $DocRevisions{$DocRevID}{Title};
  my $FullID = &FullDocumentID($DocRevisions{$DocRevID}{DOCID},$DocRevisions{$DocRevID}{VERSION});
  my $URL    = &DocumentURL($DocRevisions{$DocRevID}{DOCID});
  
  &FetchAuthor($DocRevisions{$DocRevID}{Submitter});
  my $Submitter = $Authors{$DocRevisions{$DocRevID}{Submitter}}{FULLNAME};

  my @AuthorIDs = &GetRevisionAuthors($DocRevID);
  my @TopicIDs  = &GetRevisionTopics($DocRevID);
  
  my @Authors = ();
  foreach $AuthorID (@AuthorIDs) {
    &FetchAuthor($AuthorID);
  }
  @AuthorIDs = sort byLastName @AuthorIDs;
  foreach $AuthorID (@AuthorIDs) {
    push @Authors,$Authors{$AuthorID}{FULLNAME};
  }
  my $Authors = join ', ',@Authors;
  
  my @Topics = ();
  foreach $TopicID (@TopicIDs) {
    &FetchAuthor($TopicID);
  }
  @TopicIDs = sort byTopic @TopicIDs;
  foreach $TopicID (@TopicIDs) {
    push @Topics,$MinorTopics{$TopicID}{Full};
  }
  my $Topics = join ', ',@Topics;
  
  # Construct the mail body
  
  print $Mailer "       Title: ",$DocRevisions{$DocRevID}{Title},"\n";
  print $Mailer " Document ID: ",$FullID,"\n";
  print $Mailer "         URL: ",$URL,"\n";
  print $Mailer "        Date: ",$DocRevisions{$DocRevID}{DATE},"\n";;
  print $Mailer "Requested by: ",$Submitter,"\n";;
  print $Mailer "     Authors: ",$Authors,"\n";;
  print $Mailer "      Topics: ",$Topics,"\n";;
  print $Mailer "    Keywords: ",$DocRevisions{$DocRevID}{Keywords},"\n";;
  print $Mailer "    Abstract: ",$DocRevisions{$DocRevID}{ABSTRACT},"\n";;
}

sub SendEmail (%) {
  require Mail::Send;
  require Mail::Mailer;

  my (%Params) = @_;
  
  my @Addressees = @{$Params{-to}};
  my $From       =   $Params{-from}    || "$Project Document Database <$DBWebMasterEmail>";
  my $Subject    =   $Params{-subject} || "$Project Document Database";
  my $Body       =   $Params{-body}    || "";
     
  my %Headers = ();
   
  if (@Addressees) {
    my $Mailer = new Mail::Mailer 'smtp', Server => $MailServer;
    $Headers{To}      = \@Addressees;
    $Headers{From}    = $From;
    $Headers{Subject} = $Subject;
    
    $Mailer -> open(\%Headers);    # Start mail with headers
    print $Mailer $Body;
    $Mailer -> close;              # Complete the message and send it
  }
  return int(@Addressees);
}

sub UsersToNotify ($$) {
  require "NotificationSQL.pm";
  my ($DocRevID,$Mode) = @_;

  &GetTopics;

  &FetchDocRevisionByID($DocRevID);
  my $DocumentID = $DocRevisions{$DocRevID}{DOCID};
  my $Version    = $DocRevisions{$DocRevID}{Version};

  my $UserID;
  my $Table;
  my %UserIDs = (); # Hash to make user IDs unique (one notification per person)
  my @Addressees = ();

# Get users interested in this particular document (only immediate)
 
  if ($Mode eq "immediate") {
    my $DocFetch   = $dbh -> prepare("select EmailUserID from EmailDocumentImmediate where DocumentID=?");
    $DocFetch -> execute($DocumentID);
    $DocFetch -> bind_columns(undef,\($UserID));
    while ($DocFetch -> fetch) {
      $UserIDs{$UserID} = 1; 
    }
  }

# Notification by topics 
  
  if ($Mode eq "immediate") {
    $Table = "EmailTopicImmediate";
  } elsif ($Mode eq "daily")  {
    $Table = "EmailTopicDaily";
  } elsif ($Mode eq "weekly")  {
    $Table = "EmailTopicWeekly";
  } else {   
    return;
  }    

# Get users interested in all documents for this reporting period

  my $AllFetch   = $dbh -> prepare(
    "select EmailUserID from $Table where MinorTopicID=0 and MajorTopicID=0");
  $AllFetch -> execute();
  $AllFetch -> bind_columns(undef,\($UserID));
  while ($AllFetch -> fetch) {
    $UserIDs{$UserID} = 1; 
  }

# Get users interested in major or minor topics for this reporting period

  my $MinorFetch   = $dbh -> prepare(
    "select EmailUserID from $Table where MinorTopicID=?");
  my $MajorFetch   = $dbh -> prepare(
    "select EmailUserID from $Table where MajorTopicID=?");

  my @MinorTopicIDs = &GetRevisionTopics($DocRevID);
  foreach my $MinorTopicID (@MinorTopicIDs) {
    $MinorFetch -> execute($MinorTopicID);
    $MinorFetch -> bind_columns(undef,\($UserID));
    while ($MinorFetch -> fetch) {
      $UserIDs{$UserID} = 1; 
    }

    my $MajorTopicID = $MinorTopics{$MinorTopicID}{MAJOR};
    $MajorFetch -> execute($MajorTopicID);
    $MajorFetch -> bind_columns(undef,\($UserID));
    while ($MajorFetch -> fetch) {
      $UserIDs{$UserID} = 1; 
    }
  }  

# Notification by authors 
  
  if ($Mode eq "immediate") {
    $Table = "EmailAuthorImmediate";
  } elsif ($Mode eq "daily")  {
    $Table = "EmailAuthorDaily";
  } elsif ($Mode eq "weekly")  {
    $Table = "EmailAuthorWeekly";
  }    

# Get users interested in authors for this reporting period

  my $AuthorFetch   = $dbh -> prepare(
    "select EmailUserID from $Table where AuthorID=?");

  my @AuthorIDs = &GetRevisionAuthors($DocRevID);

  foreach my $AuthorID (@AuthorIDs) {
    $AuthorFetch -> execute($AuthorID);
    $AuthorFetch -> bind_columns(undef,\($UserID));
    while ($AuthorFetch -> fetch) {
      $UserIDs{$UserID} = 1; 
    }
  }  

# Notification by keywords
  
  if ($Mode eq "immediate") {
    $Table = "EmailKeywordImmediate";
  } elsif ($Mode eq "daily")  {
    $Table = "EmailKeywordDaily";
  } elsif ($Mode eq "weekly")  {
    $Table = "EmailKeywordWeekly";
  }    

# Get users interested in authors for this reporting period

  my $KeywordFetch   = $dbh -> prepare(
    "select EmailUserID from $Table where Keyword=lower(?)");
  &FetchDocRevisionByID($DocRevID);
  my @Keywords = split /\s+/,$DocRevisions{$DocRevID}{Keywords};

  foreach my $Keyword (@Keywords) {
    $Keyword =~ tr/[A-Z]/[a-z]/;
    $KeywordFetch -> execute($Keyword);
    $KeywordFetch -> bind_columns(undef,\($UserID));
    while ($KeywordFetch -> fetch) {
      $UserIDs{$UserID} = 1; 
    }
  }  

# Translate UserIDs into E-mail addresses, 
# verify user is allowed to receive notification
   
  foreach $UserID (keys %UserIDs) {
    my $EmailUserID = &FetchEmailUser($UserID);
    if ($EmailUserID && &CanAccess($DocumentID,$Version,$EmailUserID)) {
      my $Name         = $EmailUser{$UserID}{Name}        ; # FIXME: TRYME: Have to use UserID as index for some reason
      my $EmailAddress = $EmailUser{$UserID}{EmailAddress};
      if ($EmailAddress) {
        push @Addressees,$EmailAddress;
      }
    }
  } 
  
  return @Addressees;
}

sub EmailTopicForm($$) {
  require "NotificationSQL.pm";
  my ($EmailUserID,$Set) = @_;
  &FetchTopicNotification($EmailUserID,$Set);
  &NotifyTopicSelect($Set);
}

sub EmailAuthorForm($$) {
  require "NotificationSQL.pm";
  my ($EmailUserID,$Set) = @_;
  &FetchAuthorNotification($EmailUserID,$Set);
  &NotifyAuthorSelect($Set);
}

sub EmailKeywordForm($$) {
  require "NotificationSQL.pm";
  my ($EmailUserID,$Set) = @_;
  &FetchKeywordNotification($EmailUserID,$Set);
  &NotifyKeywordEntry($Set);
}

sub DisplayNotification($$;$) {
  my ($EmailUserID,$Set,$Always) = @_;

  require "NotificationSQL.pm";
  require "TopicHTML.pm";
  require "AuthorHTML.pm";

  &FetchTopicNotification($EmailUserID,$Set);
  &FetchAuthorNotification($EmailUserID,$Set);
  &FetchKeywordNotification($EmailUserID,$Set);
  
  if ($NotifyAllTopics || @NotifyMajorIDs || @NotifyMinorIDs ||
      @NotifyAuthorIDs || @NotifyKeywords) {
    print "<li>$Set notifications:\n";  
    print "<ul>\n";  
  } elsif ($Always) {
    print "<li>$Set notifications:\n";  
    print "<ul>\n";  
    print "<li>None\n";  
    print "</ul>\n";
    return;
  } else {
    return;
  }
  if ($NotifyAllTopics) {
    print "<li>All documents\n";  
  }  
  
  if (@NotifyMajorIDs) {
    foreach my $MajorID (@NotifyMajorIDs) {
      print "<li> Topic: ",&MajorTopicLink($MajorID)," ";
    }
  }
    
  if (@NotifyMinorIDs) {
    foreach my $MinorID (@NotifyMinorIDs) {
      print "<li> Subtopic: ",&MinorTopicLink($MinorID)," ";
    }
  }
    
  if (@NotifyAuthorIDs) {
    foreach my $AuthorID (@NotifyAuthorIDs) {
      print "<li> Author: ",&AuthorLink($AuthorID)," ";
    }
  }
    
  if (@NotifyKeywords) {
    foreach my $Keyword (@NotifyKeywords) {
      print "<li>Keyword: $Keyword  ";
    }
  }
    
  print "</ul>\n";  
}

sub NotifyTopicSelect ($) { # Check for all, boxes for major and minor topics
  my ($Set) = @_;

  print "<td valign=top>\n";
  print "<b><a ";
  &HelpLink("notifytopic");
  print "$Set:</a></b><p>\n";
  if ($NotifyAllTopics) {
    print $query -> checkbox(-name => "all$Set", -checked => 'checked', -value => 1, -label => '');
  } else {
    print $query -> checkbox(-name => "all$Set", -value => 1, -label => '');
  }                             
  print "<b> All Topics</b> ";

  print "<td>\n";
  my @MajorIDs = sort byMajorTopic keys %MajorTopics;
  my %MajorLabels = ();
  foreach my $ID (@MajorIDs) {
    $MajorLabels{$ID} = $MajorTopics{$ID}{SHORT};
  }  
  print $query -> scrolling_list(-name => "majortopic$Set", -values => \@MajorIDs, 
                                 -labels => \%MajorLabels,  
                                 -size => 10, -default => \@NotifyMajorIDs,
                                 -multiple => 'true');
  print "</td>\n";
  
  print "<td colspan=2>\n";
  my @MinorIDs = sort byTopic keys %MinorTopics;
  my %MinorLabels = ();
  foreach my $ID (@MinorIDs) {
    $MinorLabels{$ID} = $MinorTopics{$ID}{Full};
  }  
  
  print $query -> scrolling_list(-name => "minortopic$Set", -values => \@MinorIDs, 
                                 -labels => \%MinorLabels,  
                                 -size => 10, -default => \@NotifyMinorIDs,
                                 -multiple => 'true');
  print "</td>\n";
}

sub NotifyAuthorSelect ($) { 
  my ($Set) = @_;

  print "<td valign=top>\n";
  print "<b><a ";
  &HelpLink("notifyauthor");
  print "$Set:</a></b><br>\n";

  my @AuthorIDs = sort byLastName keys %Authors;
  my %AuthorLabels = ();
  foreach my $ID (@AuthorIDs) {
    $AuthorLabels{$ID} = $Authors{$ID}{FULLNAME};
  }  
  print $query -> scrolling_list(-name => "author$Set", -values => \@AuthorIDs, 
                                 -labels => \%AuthorLabels,  
                                 -size => 10, -default => \@NotifyAuthorIDs,
                                 -multiple => 'true');
  print "</td>\n";
}
  
sub NotifyKeywordEntry ($) { 
  my ($Set) = @_;

  print "<tr><td align=left>\n";
  print "<b><a ";
  &HelpLink("notifykeyword");
  print "$Set:</a></b> (separate with spaces)<br>\n";

  foreach my $ID (@AuthorIDs) {
    $AuthorLabels{$ID} = $Authors{$ID}{FULLNAME};
  }  
  print $query -> textfield (-name => "keyword$Set", -default => $NotifyKeywords, 
                             -size => 80, -maxlength => 240);
  print "</td></tr>\n";
}

sub EmailUserSelect (%) {

  my (%Params) = @_;
  
  my $Disabled = $Params{-disabled}  || "0";
  
  my $Booleans = "";
  
  if ($Disabled) {
    $Booleans .= "-disabled";
  }  
  
  my @EmailUserIDs = &GetEmailUserIDs;
  foreach my $EmailUserID (@EmailUserIDs) {
    &FetchEmailUser($EmailUserID);  
    $EmailUserLabels{$EmailUserID} = $EmailUser{$EmailUserID}{Username};
  }  
  
  print "<b><a ";
  &HelpLink("emailuser");
  print "Username:</a></b><br> \n";
  print $query -> scrolling_list(-name => 'emailuserid', 
                                 -values => \@EmailUserIDs, 
                                 -labels => \%EmailUserLabels, 
                                 -size => 10, $Booleans);

}
  
1;
