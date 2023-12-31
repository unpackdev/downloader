// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 People Portraits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    =========-===+***++================================-----==================================+++++++++=====++++++++++++    //
//    ==============+****+================================--===============================+++++++++++++====++++++++++++++    //
//    +===============+**++==========================================================++++++++++++++++++====+++++++++++++++    //
//    ++++=============++++================================-=======++++=++++++++++++++++++++++++++++++===+++++++++++++++**    //
//    ***+++++============================================----=========================================++++++++++++++***++    //
//    *##****+++++++++++++++++++++++++++++++++++++++++++==========+++++++++++++++++++++++++++++++++++++++*************++++    //
//    #####*******************+*+++++++++++++++++++++++++***##******###***************************************************    //
//    #*******+++++++++++++++++++++++++++++++++++++=++***#######***########*++++++++++++++++++++++++++++++++++++++++++++++    //
//    ######********************++++*****+++++++===+******######***###########********************************************    //
//    %########****####*********************+++===++++*****####****######%##%####****###*****#####*****##############*####    //
//    %#####*****####***************+++++++*+=--==++++++*##**++++++**##%%%#%%%%###*******************####*******######****    //
//    #######******##*************++++*+++++=---=====+***++======++++**#%%%%%%%%###*******************####*****#####******    //
//    ##########******##******************+=---==--+#*+============+++**#%%%%%%%%%##*##******#######***#############**####    //
//    #**************+++++++++++++++++++++=---==--*#*+=---=========++++*##%%%%%%%%%##****++*******************************    //
//    ++++===============================----==--*##+=-----========+++++##*#%%%%%%%%#*+=========================++++++++++    //
//    *+++++=============================--=-==-=##*=------========+++++*####%%%%%%%%#*+++++++++++++++++++++++++++++++++++    //
//    *++++++===========================----==--*##+==============++++****####%%%%%%%##*++++++++++++++++++++++++++++++++++    //
//    *++++=============================--=-==-=#%*+++++***+====++*##******####%%%%%%%##++++++++++++++++++++++++++++++++++    //
//    ++===========-------------======--------=+#%#***###**+=--=+*****#%#%######%%%%%%%#*+================================    //
//    +=====-----------------------==---------+*#%##*++**+*+---=***+++*#########%%%%%%%#*++++++++++++====+++++===++++++++=    //
//    ++++=============================------=*###*+========--=+****+++++***#####%%%%%%##+++++++++++++++++++++++++++++++++    //
//    +++=============================------=+####*===-=------=++***+++++++**#####%%%%%##*++++++++++++++++++++++++++++++++    //
//    ++=====================---======------+*####+==---------==+***++++++***#%%###%%%%##*+++=========++++++++++++++++++++    //
//    ++===================-----====-------=**##%#*==------==+=+****+++++***##%%####%%###*+============+++++++++++++++++++    //
//    +++===================---===-------===*###%%#+==--------==++++++++***##%%######%%%##**+++++++====+++++++++++++++++++    //
//    +++====----======-=+==-----------=====**##%%#*+==------=++++++++****###%%#######%####*******+====+++++++++++++++++++    //
//    **+================++==---------======**###%%#+====+++++****####***###%%%#############******+====+++++++++++++++++++    //
//    **+==+=============++==--------==+==-=**###%@%#+=====+++**********###%@%##########%####*****+====+++++++++++++++++++    //
//    +++===+======+++===++=====----==+=--=***#%#%%@%#+========+++*****##%%@%############%####*****====+++++++++++++++++++    //
//    *+==--=============+*++++==--====--=***#%%%%%@%%%#+======+++****##%%%%%############%%%##*****+===+++++++++++++++++++    //
//    +++==========+++=++*##**+=----=--=+**###%%%%%%%%%%%#*+++++***###%%%%%%##############%%%#####*+===+++++++++++++++**++    //
//    ++++++++***********####*+=------=++*###%%%%%%%%%%%####*****#######%%%#####**###%####%%%#####*+===+*+++++=---===++**+    //
//    ++++===========++++**++==------=+++###%%%%%%%%%%%####********#####%%%##**##*##%####%%%%######+===+*+++++=---==++++++    //
//    ++===============+++++=-----===+**#*##%%%%%%%@%%%###************###%%%##*#####%####%%%%######+===+**++++====++======    //
//    +==============+++++++=----===+***##%%%%%%%%@@%%%###*************###%%%############%%%%#####*+==+*************++++++    //
//    ++========-::--=+***+==----===+**###%%%%%%%%%%%%%###*************###################%%%%##*##*****###******#********    //
//    +++++===+=--:--=+***+==-----==++**##%%#%%%@@%%%%%####*************################*##%%%######***####****####*******    //
//    ***++=========++***+==-------=+++**####%%%%%%%%%%####*****++******#########**####*#*##%######***###########%###*+***    //
//    ***************++=-==-------=+++*#*#%%%%%%%%%%%%######************#########**###%#*###%%%#######****#%%%%%%###***###    //
//    #######****++=---====------=+***#**#%%%%%%%%%%%#######*******##############**####%#*####%%%#######****#%%%%%%%%%%%%%    //
//    ##******++=---===+++==---===++****#%%%%%%%%%%%##############*********######**##%%%%%#####%%%#######********######%%#    //
//    ++++++***+--=++=++++==--===+++**+#%%%%%%%%%%%%########**#######******##%###***##%%%%%#%%##%%%%#######******####%%%%%    //
//    +++++++*+=--==+++++==+==+++***++*#%%%%%%%%%%%%%#%%##******##***#######%%###*+*###%%%%%%%%%%%%%%#######****#####%%%%%    //
//    #******+=--+==++=+++=+=+*****++*#%%%%%%%%%%%%%%####*******##*******#########***###%%%%%%%%%%%%%%##########*##%%%%%%%    //
//    %%%###*+===++==++=++=+++*****++*#%%%%%%%%%%%%%####*********#*********#######****##%%%%%%%%%%%%%%%############%%%%%%%    //
//    %%%%%#*====+*+==++++++++**+**++*##%%%%%%%%%%%%####*********#**********#########*###%%%%%%%%%%%%%%###############%%%%    //
//    %%%%##+====+**+=+==++++++++**++###%%%%%%%%%%%####**********#**********#############%%%%%%%%%%%%%%###########*##%%%%%    //
//    #####*===+=+*+++===+++==+++**++*##%%%%%%%%%%%####********+*#***********########**##%%%%%%%%%%%%%%%##############%%%%    //
//    **+++=-=+++=+**++++++====+***++***#%%%%%%%%%%###*********+*#*************######***#%%%%%%%%%%%%%%%%%#########*###%%%    //
//    +++++--=+++=+***++++====+****+++**##%%%%%%%%####******+*++*#*************#####***##%%%%%%%%%%%%%%%%%#########****###    //
//    ****+--=+*+=++****++===++***+++++*###%%%#%#####*******+++*#**************#####**###%%%%%%%%%%%%%%%%###########****##    //
//    ####+--=+*++=+**#**++++****+++++**######%######******++++****++++********####****#%%%%%%%#%%%%%%%%%%##########*+++**    //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract W3PP is ERC721Creator {
    constructor() ERC721Creator("Web3 People Portraits", "W3PP") {}
}
