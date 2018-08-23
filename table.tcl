#!/usr/bin/tclsh

proc GetRowList { RowORCol Matrix } {
    if { [string equal $RowORCol Row] } {
        for {set i 0} {$i < [llength $Matrix]} {incr i} {
            lappend RowList [lindex $Matrix $i]
        }
    } elseif { [string equal $RowORCol Col] } {
        set iLen [llength [lindex $Matrix 0]]
        set jLen [llength $Matrix]
        for {set i 0} {$i < $iLen} {incr i} {
            set Row ""
            for {set j 0} {$j < $jLen} {incr j} {
                lappend Row [lindex [lindex $Matrix $j] $i]
            }
            lappend RowList $Row
        }
    } else {
        exit
    }
    return $RowList
}

proc GetColMaxLen { RowList ColNum Align } {
    for {set i 0} {$i < $ColNum} {incr i} {
        lappend ColMaxLen 0
    }
    foreach Row $RowList {
        for {set i 0} {$i < $ColNum} {incr i} {
            set AlignType [lindex $Align $i]
            if { [regexp {(\d+)?.(\d)f} $AlignType match int dec] } {
                set ColLen [expr $int + $dec +1]
            } elseif { [regexp {(\d+)} $AlignType len] } {
                set ColLen $len
            } else {
                set ColLen 0
            }
            set StrLen [string length [lindex $Row $i]]
            set ColLen [GetBigger $ColLen $StrLen]
            if { $ColLen > [lindex $ColMaxLen $i] } {
                lset ColMaxLen $i $ColLen
            }
        }
    }
    return $ColMaxLen
}

proc GetSplitLine { BodyRow HChar VChar CChar } {
    set SplitLine $BodyRow
    set SplitLine [regsub -all "\[^$VChar\]" $SplitLine $HChar]
    set SplitLine [regsub -all "\[$VChar\]"  $SplitLine $CChar]
    set SplitLine [regsub -all "^.|.$"       $SplitLine $VChar]
    return $SplitLine
}

proc GetBodyRow { ColList ColMaxLen AlignList LPadding RPadding VChar } {
    set ColNum [llength $ColList]
    set BodyRow $VChar
    for {set i 0} {$i < $ColNum} {incr i} {
        set FormatCell  [AlignString  \
            [lindex $ColList   $i] \
            [lindex $ColMaxLen $i] \
            [lindex $AlignList $i] \
        ]
        append BodyRow "$LPadding$FormatCell$RPadding$VChar"
    }
    return $BodyRow
}

proc GetCenterFormat { String Length } {
    set m [string length $String]
    set t [expr $Length - $m]
    set l [expr $t / 2]
    set r [expr $l + ($t % 2)]
    return "%-${l}s%${m}s%${r}s"
}

proc parse_proc_arguments { procArgs optsRef } {
    upvar $optsRef opts
    foreach arg $procArgs {
        if { [string index $arg 0] == "-" } {
            set curArg $arg
            set opts($curArg) 1
        } else {
            if { [info exists curArg] } {
                set opts($curArg) $arg
                unset curArg
            }
        }
    }
    return
}

proc GetLine { Length Char } {
    set Line ""
    for {set i 0 } { $i < $Length} {incr i} {
        append Line $Char
    }
    return $Line
}

proc GetBigger {a b} {
    if { $a > $b } {
        return $a
    } else { 
        return $b
    }
}

proc AlignString { String Length Type } {
    if { [regexp {(\d+)?.(\d)f} $Type Pattern int dec] } {
        if { [regexp {^\d+\.\d+$} $String]} {
            set len [expr $int + $dec +1]
            set Length [GetBigger $Length $len]
            return [format "%${Length}s" [format "%$Pattern" $String]]
        } else {
            return [format "%${Length}s" $String]
        }
    } elseif { [regexp {Left(\d+)?} $Type match len] } {
        set Length [GetBigger $Length $len]
        return [format "%-${Length}s" $String]
    } elseif { [regexp {Right(\d+)?} $Type match len] } {
        set Length [GetBigger $Length $len]
        return [format "%${Length}s" $String]
    } else { ;# default AlignType : center
        return [format [GetCenterFormat $String $Length] "" $String ""]
    }
}

proc PrintTable { args } {
    set options(-Title)         ""
    set options(-AlignType)     ""
    set options(-Header)        ""
    set options(-HSplitChar)    -
    set options(-VSplitChar)    |
    set options(-CrossChar)     +
    set options(-LPadding)      " "
    set options(-RPadding)      " "
    set options(-Margin)        \t
    set options(-TitleLine)     1
    set options(-HeaderLine)    1
    set options(-BlankLine)     1
    set options(-FirstLine)     1
    set options(-LastLine)      1
    set options(-SplitLine)     0
    set options(-Debug)         0

    parse_proc_arguments $args options

    set Title           $options(-Title)
    set Header          $options(-Header)
    set HChar           $options(-HSplitChar)
    set VChar           $options(-VSplitChar)
    set CChar           $options(-CrossChar)
    set LPadding        $options(-LPadding)
    set RPadding        $options(-RPadding)
    set Margin          $options(-Margin)
    set Align           $options(-AlignType)
    set Debug           $options(-Debug)
    set PrintFisrtLine  $options(-FirstLine)
    set PrintLastLine   $options(-LastLine)
    set PrintSplitLine  $options(-SplitLine)
    set PrintBlankLine  $options(-BlankLine)
    set PrintTitleLine  $options(-TitleLine)
    set PrintHeaderLine $options(-HeaderLine)

    #Get RowList
    set option_list [array name options]
    if { $Debug } { puts [array get options] }
    if { [regexp {\-Row} $option_list] } {
        set RowList [GetRowList Row $options(-Row)]
    } elseif { [regexp {\-Col} $option_list] } {
        set RowList [GetRowList Col $options(-Col)]
    } else {
        exit
    }

    set ColNum [llength [lindex $RowList 0]]

    if {[llength $VChar]  == 0} { 
        set CChar $HChar
        set PrintFisrtLine 0
        set PrintLastLine  0
    }
    if {[llength $Header] == 0} { 
        set PrintHeaderLine 0
        set Header [lrepeat $ColNum "*"]
    }
    if {[llength $Title]  == 0} { 
        set PrintTitleLine 0
    }

    #Get Each Col Max Length
    set AllRow          [concat $RowList [list $Header]]
    set ColMaxLen       [GetColMaxLen $AllRow $ColNum $Align]

    set HeaderLine      [GetBodyRow $Header $ColMaxLen $Align $LPadding $RPadding $VChar]
    set RowLen          [string length $HeaderLine]
    set HLine           [GetLine $RowLen $HChar]

    if {$PrintFisrtLine}    {
        set TitleLine   [format [GetCenterFormat $Title $RowLen] $VChar $Title $VChar]
    } else {
        set TitleLine   [format [GetCenterFormat $Title $RowLen] " " $Title " "]
    }
    set SplitLine       [GetSplitLine $HeaderLine $HChar $VChar $CChar]
    set FirstLine       [regsub -all "^.|.$" $HLine "." ]
    set LastLine        [regsub -all "^.|.$" $HLine "'" ]

    #Get Print Buffer
    #
    #Print    Print    Print
    #First    Last     Title
    #  0        0        0
    #  0        0        1             title + first*
    #  0        1        0                             last
    #  0        1        1             title + first*+ last
    #  1        0        0     first
    #  1        0        1     first + title + split
    #  1        1        0     first                 + last
    #  1        1        1     first + title + split + last
    set PrintBuffer ""
    if {$PrintBlankLine}        {lappend PrintBuffer ""}
    if {$PrintFisrtLine}        {lappend PrintBuffer $FirstLine}
    if {$PrintTitleLine}        {lappend PrintBuffer $TitleLine
        if {!$PrintFisrtLine}   {lappend PrintBuffer $FirstLine
        } else {                 lappend PrintBuffer $SplitLine}}
    if {$PrintHeaderLine}       {lappend PrintBuffer $HeaderLine}
    
    foreach Row $RowList {
        if {$PrintSplitLine}    {lappend PrintBuffer $SplitLine}
                                 lappend PrintBuffer [GetBodyRow $Row $ColMaxLen $Align $LPadding $RPadding $VChar] }
    if {$PrintLastLine}         {lappend PrintBuffer $LastLine}
    if {$PrintBlankLine}        {lappend PrintBuffer ""}

    #Print Table
    foreach line $PrintBuffer {
        puts $Margin$line
    }
}

set AlignType [list "Center7" "Center7" "5.3f"] 
set Row [list \
    [list 1 "one" "0.01"] \
    [list 1 "one" "0.01"] \
    [list 1 "one" "0.01"] \
    [list 1 "one" "0.01"] \
]

set Header [list "aaaaa" "index" "comment" ]

#PrintTable  -Row $Row  \
            -Header $Header  \
            -AlignType $AlignType \
            -VSplitChar " " \
            -HeaderLine 0 \
            -TitleLine 0 \
            -BlankLine 


#PrintTable  -VSplitChar " " \
            -AlignType $AlignType \
            -LPadding < \
            -RPadding > \
            -Row $Row  

#PrintTable  -Row $Row   -Title "Title" -FirstLine 1 -LastLine 1 -TitleLine 1
PrintTable -Row $Row -Header $Header -Title "TableTitle"
PrintTable -Row $Row -Header $Header -Title "TableTitle" -FirstLine 0
PrintTable -Row $Row -Header $Header -Title "TableTitle" -LastLine 0
PrintTable -Row $Row -Header $Header -Title "TableTitle" -SplitLine
PrintTable -Row $Row -Header $Header  -FirstLine 0 -LastLine 0
