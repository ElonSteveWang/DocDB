#
#        Name: TopicHTML.pm
# Description: Routines to produce snippets of HTML dealing with topics 
#              (major, minor and conferences which are special types of topics) 
#
#      Author: Eric Vaandering (ewv@fnal.gov)
#    Modified: 
#

sub TopicListByID {
  my @topicIDs = @_;
  if (@topicIDs) {
    print "<b>Topics:</b><br>\n";
    print "<ul>\n";
    foreach $topicID (@topicIDs) {
      &FetchMinorTopic($topicID);
      my $topic_link = &MinorTopicLink($topicID);
      print "<li> $topic_link </li>\n";
    }
    print "</ul>\n";
  } else {
    print "<b>Topics:</b> none<br>\n";
  }
}

sub ShortTopicListByID {
  my @topicIDs = @_;
  if (@topicIDs) {
    foreach $topicID (@topicIDs) {
      &FetchMinorTopic($topicID);
      my $topic_link = &MinorTopicLink($topicID);
      print "$topic_link <br>\n";
    }
  } else {
    print "None<br>\n";
  }
}

sub MinorTopicLink ($;$) {
  my ($TopicID,$mode) = @_;
  
  require "TopicSQL.pm";
  
  &FetchMinorTopic($TopicID);
  my $link;
  $link = "<a href=\"$ListByTopic?topicid=$TopicID\" title=\"$MinorTopics{$TopicID}{LONG}\">";
  if ($mode eq "short") {
    $link .= $MinorTopics{$TopicID}{SHORT};
  } elsif ($mode eq "long") {
    $link .= $MinorTopics{$TopicID}{LONG};
  } else {
    $link .= $MinorTopics{$TopicID}{FULL};
  }
  $link .= "</a>";
  
  return $link;
}

sub MajorTopicLink ($;$) {
  my ($TopicID,$mode) = @_;
  
  require "TopicSQL.pm";
  
  &FetchMajorTopic($TopicID);
  my $link;
  $link = "<a href=\"$ListByTopic?majorid=$TopicID\" title=\"$MajorTopics{$TopicID}{LONG}\">";
  if ($mode eq "short") {
    $link .= $MajorTopics{$TopicID}{SHORT};
  } elsif ($mode eq "long") {
    $link .= $MajorTopics{$TopicID}{LONG};
  } else {
    $link .= $MajorTopics{$TopicID}{SHORT};
  }
  $link .= "</a>";
  
  return $link;
}

sub GatheringLink {
  my ($TopicID,$Mode) = @_;
  my $MajorID = $MinorTopics{$TopicID}{MAJOR};
  my $Link;
  if (&MajorIsConference($MajorID)) {
    $Link = &ConferenceLink($TopicID,$Mode);
  } elsif (&MajorIsMeeting($MajorID)) {
    $Link = &MeetingLink($TopicID,$Mode);
  }
}

sub MeetingLink {
  my ($TopicID,$Mode) = @_;
  
  require "TopicSQL.pm";
  
  &FetchMinorTopic($TopicID);
  my $link;
  $link = "<a href=\"$ListByTopic?topicid=$TopicID&mode=meeting\" title=\"$MinorTopics{$TopicID}{LONG}\">";
  if ($Mode eq "short") {
    $link .= $MinorTopics{$TopicID}{SHORT};
  } else {
    $link .= $MinorTopics{$TopicID}{FULL};
  }
  $link .= "</a>";
  
  return $link;
}

sub ConferenceLink {
  my ($TopicID,$Mode) = @_;
  
  require "TopicSQL.pm";
  
  &FetchMinorTopic($TopicID);
  my $Link;
     $Link = "<a href=$ListByTopic?topicid=$TopicID&mode=conference>";
  if ($Mode eq "short" || $Mode eq "nodate") {
    $Link .= $MinorTopics{$TopicID}{SHORT};
  } elsif ($Mode eq "long") {
    $Link .= $MinorTopics{$TopicID}{LONG};
  } else {
    $Link .= $MinorTopics{$TopicID}{FULL};
  }
  $Link .= "</a>";
  unless ($Mode eq "nodate") {
    my ($Year,$Month,$Day) = split /\-/,$Conferences{$TopicID}{StartDate};
    $Link .= " (".@AbrvMonths[$Month-1]." $Year)"; 
  }
  return $Link;
}

sub TopicsByMajorTopic ($) {
  my ($MajorTopicID) = @_;
  
  require "Sorts.pm";

  my @MinorTopicIDs = sort byTopic keys %MinorTopics;

  my $MajorLink = &MajorTopicLink($MajorTopicID,"short");
  print "<b>$MajorLink</b>\n";
  print "<ul>\n";
  foreach my $MinorTopicID (@MinorTopicIDs) {
    if ($MajorTopicID == $MinorTopics{$MinorTopicID}{MAJOR}) {
      my $TopicLink = &MinorTopicLink($MinorTopicID,"short");
      print "<li>$TopicLink</li>\n";
    }  
  }  
  print "</ul>\n";
}

sub TopicsTable {
  require "Sorts.pm";

  my $NCols = 4;
  my @MajorTopicIDs = sort byMajorTopic keys %MajorTopics;

  my $Col   = 0;
  my $Row   = 0;
  print "<table cellpadding=10>\n";
  foreach my $MajorID (@MajorTopicIDs) {
    unless ($Col % $NCols) {
      if ($Row) {
        print "</tr>\n";
      }  
      print "<tr valign=top>\n";
      ++$Row;
    }
    print "<td>\n";
    &TopicsByMajorTopic($MajorID);
    print "</td>\n";
    ++$Col;
  }  
  print "</tr>\n";
  print "</table>\n";
}

sub GatheringTable {
  require "Sorts.pm";
  require "TopicSQL.pm";
  
  my @MinorTopicIDs = sort byTopic keys %MinorTopics; #FIXME special sort 

  print "<table cellpadding=4>\n";

  print "<tr>\n";
  print "<th>Name</th>\n";
  print "<th>Full Name</th>\n";
  print "<th>Location</th>\n";
  print "<th>Dates</th>\n";
  print "<th>Homepage</th>\n";
  print "</tr>\n";
  
  foreach my $MajorID (@GatheringMajorIDs) { 
    print "<tr>\n";
    print "<th colspan=5><hr></th>\n";
    print "</tr>\n";
    print "<tr>\n";
    print "<th colspan=5>$MajorTopics{$MajorID}{SHORT}</th>\n";
    print "</tr>\n";

    foreach my $MinorID (@MinorTopicIDs) {
      if ($MajorID == $MinorTopics{$MinorID}{MAJOR}) {
        print "<tr>\n";
        my $GatheringLink = &GatheringLink($MinorID,"short");
        my $Start = &EuroDate($Conferences{$MinorID}{StartDate});
        my $End   = &EuroDate($Conferences{$MinorID}{EndDate});
        my $Link;
        if ($Conferences{$MinorID}{URL}) {
          $Link = "<a href=\"$Conferences{$MinorID}{URL}\">$Conferences{$MinorID}{URL}</a>";
        } else {
          $Link = "None entered\n";
        }
        print "<td>$GatheringLink</td>\n";
        print "<td>$MinorTopics{$MinorID}{LONG}</td>\n";
        print "<td>$Conferences{$MinorID}{Location}</td>\n";
        print "<td>$Start - $End</td>\n";
        print "<td>$Link</td>\n";
        print "</tr>\n";
      }  
    }  
  }
  print "</table>";
}

sub ConferencesList {
  require "Sorts.pm";
  require "TopicSQL.pm";
  
  my @MinorTopicIDs = sort byTopic keys %MinorTopics; #FIXME special sort 

  my ($MajorID) = @ConferenceMajorIDs; 
  print "<ul>\n";
  foreach my $MinorID (@MinorTopicIDs) {
    if ($MajorID == $MinorTopics{$MinorID}{MAJOR}) {
      my $topic_link = &ConferenceLink($MinorID,"long");
      print "<li>$topic_link\n";
    }  
  }  
  print "</ul>";
}

sub MajorGatheringSelect (;$) { # Scrolling selectable list for major topics with dates
  my ($Mode) = @_; 
  
  print "<b><a ";
  &HelpLink("majortopics");
  print "Major Topics:</a></b><br> \n";
  my @MajorIDs = keys %MajorTopics;
  my @MeetingMajorIDs = ();
  foreach my $MajorID (@MajorIDs) {
    if (&MajorIsMeeting($MajorID) || &MajorIsConference($MajorID)) {
      push @MeetingMajorIDs,$MajorID;
    }
  }    
  my %MajorLabels = ();
  foreach my $ID (@MeetingMajorIDs) {
    if ($Mode eq "full") {
      $MajorLabels{$ID} = $MajorTopics{$ID}{Full};
    } else {  
      $MajorLabels{$ID} = $MajorTopics{$ID}{SHORT};
    }  
  }  
  print $query -> scrolling_list(-name => "majortopic", -values => \@MeetingMajorIDs, 
                                 -labels => \%MajorLabels,  -size => 10);
};

sub ConferenceSelect {
  require "TopicSQL.pm";
  
  my @MinorIDs           = sort byTopic keys %MinorTopics;
  my @ConferenceTopicIDs = ();
  my %TopicLabels        = ();
  foreach my $MinorID (@MinorIDs) {
    unless (&MajorIsConference($MinorTopics{$MinorID}{MAJOR}) || &MajorIsMeeting($MinorTopics{$MinorID}{MAJOR})) {
      next;
    }  
    push @ConferenceTopicIDs,$MinorID;
    $TopicLabels{$MinorID} = $MinorTopics{$MinorID}{SHORT}; 
  }  
  print "<b><a ";
  &HelpLink("conference");
  print "Conferences:</a></b> <br> \n";
  print $query -> scrolling_list(-name => "conftopic", -values => \@ConferenceTopicIDs, 
                                 -labels => \%TopicLabels, -size => 10);
}

sub MeetingsTable {
  require "Sorts.pm";
  require "TopicSQL.pm";
  
  my @MeetingTopicIDs = ();
  my @MinorTopicIDs   = keys %MinorTopics; 
  my ($MajorID) = @MeetingMajorIDs; 

  foreach my $MinorID (@MinorTopicIDs) {
    if ($MajorID == $MinorTopics{$MinorID}{MAJOR}) {
      push @MeetingTopicIDs,$MinorID;
    }  
  }  

  @MeetingTopicIDs = sort byTopic @MeetingTopicIDs; 

  my $NCols     = 3;
  my $NPerCol   = int (scalar(@MeetingTopicIDs)/$NCols + 1);
  my $NThisCol  = 0;

  print "<table>\n";
  print "<tr valign=top>\n";
  
  print "<td>\n";
  print "<ul>\n";
  foreach my $MinorID (@MeetingTopicIDs) {
    if ($NThisCol >= $NPerCol) {
      print "</ul></td>\n";
      print "<td>\n";
      print "<ul>\n";
      $NThisCol = 0;
    }
    ++$NThisCol;
    my $topic_link = &MinorTopicLink($MinorID,"short");
    print "<li>$topic_link\n";
  }  
  print "</ul></td></tr>";
  print "</table>\n";
}

1;
