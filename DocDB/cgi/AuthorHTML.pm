sub FirstAuthor {
  require "AuthorSQL.pm";

  my ($DocRevID) = @_;

  &FetchDocRevisionByID($DocRevID);
  my @AuthorIDs = &GetRevisionAuthors($DocRevID);
  
  unless (@AuthorIDs) {return "None";}
  
  my $FirstID     = $AuthorIDs[0];
  my $SubmitterID = $DocRevisions{$DocRevID}{SUBMITTER};
  foreach $AuthorID (@AuthorIDs) {
    if ($AuthorID == $SubmitterID) {
      $FirstID = $SubmitterID;  # Submitter is in list --> first author
    }  
  }
  
  my $author_link = &AuthorLink($FirstID);
  if ($#AuthorIDs) {$author_link .= " <i>et. al.</i>";}
  return $author_link; 
}

sub AuthorListByID {
  my @AuthorIDs = @_;
  
  require "AuthorSQL.pm";
  
  if (@AuthorIDs) {
    print "<b>Authors:</b><br/>\n";
    print "<ul>\n";
    foreach my $AuthorID (@AuthorIDs) {
      &FetchAuthor($AuthorID);
      my $author_link = &AuthorLink($AuthorID);
      print "<li> $author_link </li>\n";
    }
    print "</ul>\n";
  } else {
    print "<b>Authors:</b> none<br/>\n";
  }
}

sub ShortAuthorListByID {
  my @AuthorIDs = @_;
  
  require "AuthorSQL.pm";
  
  if (@AuthorIDs) {
    foreach my $AuthorID (@AuthorIDs) {
      &FetchAuthor($AuthorID);
      my $AuthorLink = &AuthorLink($AuthorID);
      print "$AuthorLink<br/>\n";
    }
  } else {
    print "<b>None<br/>\n";
  }
}

sub RequesterByID { 
  my ($RequesterID) = @_;
  my $author_link   = &AuthorLink($RequesterID);
  
  print "<tr><td align=right><b>Requested by:</b></td>";
  print "<td>$author_link</td></tr>\n";
}

sub SubmitterByID { 
  my ($RequesterID) = @_;
  my $author_link   = &AuthorLink($RequesterID);
  
  print "<tr><td align=right><b>Updated by:</b></td>";
  print "<td>$author_link</td></tr>\n";
}

sub AuthorLink {
  require "AuthorSQL.pm";
  
  my ($AuthorID) = @_;
  
  &FetchAuthor($AuthorID);
  my $link;
  $link = "<a href=$ListByAuthor?authorid=$AuthorID>";
  $link .= $Authors{$AuthorID}{FULLNAME};
  $link .= "</a>";
  
  return $link;
}

sub PrintAuthorInfo {
  require "AuthorSQL.pm";

  my ($AuthorID) = @_;
  
  &FetchAuthor($AuthorID);
  &GetInstitutions; # FIXME: Can use FetchInstitution when exists
  my $link = &AuthorLink($AuthorID);
  
  print "$link\n";
  print " of ";
  print $Institutions{$Authors{$AuthorID}{INST}}{LONG};
}

sub AuthorsByInstitution { 
  my ($InstID) = @_;
  require "Sorts.pm";

  my @AuthorIDs = sort byLastName keys %Authors;

  print "<td><b>$Institutions{$InstID}{SHORT}</b>\n";
  print "<ul>\n";
  foreach my $AuthorID (@AuthorIDs) {
    if ($InstID == $Authors{$AuthorID}{INST}) {
      my $author_link = &AuthorLink($AuthorID);
      print "<li>$author_link\n";
    }  
  }  
  print "</ul>";
}

sub AuthorsTable {
  require "Sorts.pm";

  my @AuthorIDs = sort byLastName    keys %Authors;
  my $NCols     = 4;
  my $NPerCol   = int (scalar(@AuthorIDs)/$NCols + 1);
  my $NThisCol  = 0;

  print "<table>\n";
  print "<tr valign=top>\n";
  
  print "<td>\n";
  print "<ul>\n";
  
  foreach my $AuthorID (@AuthorIDs) {

    if ($NThisCol >= $NPerCol) {
      print "</ul></td>\n";
      print "<td>\n";
      print "<ul>\n";
      $NThisCol = 0;
    }
    ++$NThisCol;
    my $author_link = &AuthorLink($AuthorID);
    print "<li>$author_link\n";
  }  
  print "</ul></td></tr>";
  print "</table>\n";
}

sub AuthorScroll ($$$;@) {
  my ($All,$Multiple,$ElementName,@Defaults) = @_;
  
  require "AuthorSQL.pm";
  
  unless (keys %Author) {
    &GetAuthors;
  }
  
  if ($Multiple) {
    $Multiple = "true";
  } else { 
    $Multiple = "false";
  }  
  
  my @AuthorIDs = sort byLastName keys %Authors;
  my %AuthorLabels = ();
  my @ActiveIDs = ();
  foreach my $ID (@AuthorIDs) {
    if ($Authors{$ID}{ACTIVE} || $All) {
      $AuthorLabels{$ID} = $Authors{$ID}{Formal};
      push @ActiveIDs,$ID; 
    } 
  }  
  print $query -> scrolling_list(-name => $ElementName, -values => \@ActiveIDs, 
                                 -labels => \%AuthorLabels,
                                 -size => 10, -multiple => $Multiple,
                                 -default => \@Defaults);
}

sub AuthorTextEntry ($;@) {
  my ($ElementName,@Defaults) = @_;
  
  my $AuthorManDefault = "";

  foreach $AuthorID (@Defaults) {
    &FetchAuthor($AuthorID);
    $AuthorManDefault .= "$Authors{$AuthorID}{FULLNAME}\n" ;
  }  
  print $query -> textarea (-name    => $ElementName, 
                            -default => $AuthorManDefault,
                            -columns => 20, -rows    => 8);
};


1;
