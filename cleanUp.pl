use file::slurp;
use File::Basename;
my %columns;   #define hash table 
@files = <"inputData/*.CSV">; #take all files into array: @files
foreach $file (@files){
	open (READFILE, $file) or die "Error - unable to open file"; #open each read file 1 by 1 over for loop
	$file =~ s/input/output/; #regex parse - write to destination folder - OUTPUT1
	my $dirname = dirname($file); #directory name 
	my $basename = basename($file,".csv"); 
	$basename .= "_out.csv";  #append to the end the new extension
	$file=$dirname ."/". $basename; #append dirname to the beginning of 'basename' for full filename. 
	open (WRITEFILE, ">>$file"); #open write file
	print WRITEFILE "Points, ElapsedTime, Disp, Load, AxialCmd, AbsForce, RelDisp, inst.stiff, forwardLoad, switch, diff \n";
	
	#initialize variables
	$firstDisp = NULL;
	$forwardLoad = NULL;
	$switch = 0; 
	$count=1
	$count2 = 0; 
	while (<READFILE>){ #inside loop to read each line within file
		chomp($_); #chomp (get ride rows /n) -- last hash in key value pair (in line) \n
		if ($_ =~m/^\d/){  #regex pattern match - read only numbers in input file - 
			($columns{Points},$columns{ElapsedTime}, $columns{ScanTime}, $columns{Disp}, $columns{Load}, $columns{AxialCmd})= split(",", $_);    #split values at commas (comma delimiter) 
			
#---------------------------------CALCULATIONS----------------------------------------
			if ($firstDisp == NULL){ #initialize absolute displacement 
				$firstDisp = $columns{Disp};
			}
			if ($forwardLoad == NULL){ #initialize forward Load 
				$forwardLoad = $columns{AbsForce};
			}	
			if ($switch == 1){
				$count2++
			}
#----Absolute Force---- 
			$columns{AbsForce} = -$columns{Load};
#----Relative Displacement----
			$columns{RelDisp} =$firstDisp - $columns{Disp};
#----instantaneous stiffness----
			if ($columns{RelDisp} != 0.0){
				$columns{stiffness} = $columns{AbsForce}/$columns{RelDisp};
			}
			else{
			$columns{stiffness} = 0.0;
			}
			if ($forwardLoad - $columns{AbsForce} > 2){ #arbitrary value of 2N - set this as change in load after fracture 
				$switch = 1; #trigger - switch 0-->1 when fracture load reached
			}
			$diff = $forwardLoad - $columns{AbsForce};
			if ($columns{AbsForce}>1.05 && $count2 < 20){ #only print values when switch trigger has not been reached 
				print WRITEFILE "$count,$columns{ElapsedTime}, $columns{Disp}, $columns{Load}, $columns{AxialCmd}, $columns{AbsForce}, $columns{RelDisp}, $columns{stiffness}, $forwardLoad, $switch, $diff \n"; #write output data into new file 
			}
			$forwardLoad = $columns{AbsForce};
			$count++
		}		
	}
}