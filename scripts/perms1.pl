#!/usr/bin/perl -w  
use strict;

$)=$(=2222; # gid
$>=$<=2222; # uid
setpgrp $$,2222;

open(FH,">new.txt");
close(FH);
