# Copyright 2001-2004 Eric Vaandering, Lynn Garren, Adam Bryant

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

sub ValidURL { # URL is valid
  my ($url) = @_;
  
  $ok = 0;
  $sep = "://";
  
  my ($service,$address) = split /$sep/,$url;
  
  unless ($service && $address) {
    return $ok;
  }
  unless (grep /^\s*[a-zA-z]+$/,$service) {
    return $ok;
  }    
  unless (grep /^[\-\w\~\;\/\?\=\&\$\.\+\!\*\'\(\)\,]+\s*$/, $address) { # no :,@
    return $ok;
  }  

  $ok = 1;
  return $ok;
}
  
sub ValidFileURL { # URL is valid and has file afterwards
  my ($url) = @_;
  
  $ok = 0;
  $sep = "://";
  
  my ($service,$address) = split /$sep/,$url;
  
  unless ($service && $address) {
    return $ok;
  }
  unless (grep /^\s*[a-zA-z]+$/,$service) {
    return $ok;
  }    
  unless (grep /^[\-\w\~\;\/\?\=\&\$\.\+\!\*\'\(\)\,]+\s*$/, $address) { # no :,@
    return $ok;
  }  
  if (grep /\/$/,$address) {
    return $ok;
  } 
  unless (grep /\//,$address) {
    return $ok;
  } 
   
  $ok = 1;
  return $ok;
}

sub ValidDate {
  my ($Day,$Month,$Year) = @_;
  
  my @MaxDays = (31,29,31,30,31,30,31,31,30,31,30,31);
  my $FebDays;
  
  $ok = 0;
  
  if ($Day < 1) {
    return $ok;
  }  
  if ($Day > $MaxDays[$Month-1]) {
    return $ok;
  }

# We're done if its not February
  
  if ($Month != 2) {
    $ok = 1;
    return $ok;
  }  

# Is it a leap year?
  
  if ($Year % 400 == 0) {
    $FebDays = 29;
  } elsif ($Year % 100 == 0) {
    $FebDays = 28      
  } elsif ($Year % 4 == 0) {
    $FebDays = 29      
  } else {
    $FebDays = 28 
  }       
  
  if ($Day > $FebDays) {
    return $ok;
  }
  
  $ok = 1;
  return $ok;  
}
  
sub DaysInMonth {
  my ($Month,$Year) = @_; # Month (1..12)
  my @MaxDays = (31,29,31,30,31,30,31,31,30,31,30,31);
  my $FebDays;
  
  if ($Month != 2) {
    return $MaxDays[$Month-1];
  } else {

# Is it a leap year?
  
    if ($Year % 400 == 0) {
      return 29;
    } elsif ($Year % 100 == 0) {
      return 28      
    } elsif ($Year % 4 == 0) {
      return 29      
    } else {
      return 28 
    }       
  }     
}  
sub NearByMeeting { # Return MinorTopicID of meeting within $MeetingWindow days
  # Our current scheme doesn't deal well with meetings that span months. 
  # Suggest in that case just to use begin date.
  use Time::Local;
  
  require "TopicSQL.pm";
  &SpecialMajorTopics;
  
  my $Now       = time();
  my @MinorIDs = keys %MinorTopics;
  foreach $ID (@MinorIDs) {
    unless (&MajorIsMeeting($MinorTopics{$ID}{MAJOR})) {next;}
    my ($MeetDays,$MeetMonthName,$MeetYear) = split /\s+/,$MinorTopics{$ID}{SHORT};
    my ($MeetBeginDay) = split /\-/,$MeetDays;
    my $MeetMonth = $ReverseFullMonth{$MeetMonthName} - 1;
    $MeetYear  = $MeetYear - 1900;
    if ($MeetBeginDay > 0 && $MeetMonth >= 0 && $MeetYear > 0) { 
      my $MeetTime  = timelocal(0,0,0,$MeetBeginDay,$MeetMonth,$MeetYear);
      if (abs($MeetTime - $Now) < $MeetingWindow*24*60*60) {
        return $ID;
      }  
    }
  }   
}  
  
1;
