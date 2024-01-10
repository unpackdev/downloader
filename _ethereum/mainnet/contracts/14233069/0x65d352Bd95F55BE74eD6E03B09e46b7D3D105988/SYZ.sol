
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SYZYGY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//    NMMMMM8MMONMNMMMNMMMMMMNNM=D8MDN8:::::::::::::::::::::::~:~~    //
//    MMMMNNMMN8NMDNMMMMMMMMNMMMOOMMMNN:::::::::::::::::::::::::~~    //
//    MMMN++I?+?++++?++++++?++=?+++??++8DDDD8DD8DDDDDDDODD88D8~:~~    //
//    MMMM???++++++++++++++++++++++++++8DDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    MMMM???++++++++++++++++++++++++++8DDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    NMMM?++++++++++++++==++++++++++++DDDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    MMMO+++++++++++=======+++++++++++DDDDDDDDDDDDDDDDD8DDDDD:~~~    //
//    MMM$++++++++=========++77?+++8+++DDDDDDDDDDDDDDDDDDDDDDD~~~~    //
//    MMMO++++++==========+Z$$ZDDDDDD++DDNDDDDDDDDDDDDDDDDDDDD:~~~    //
//    MMMZ++++============$?++I$DDDDD?+DDDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    NMMO++++===========+Z+I??IODDO?++DDDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    MMMO+++============7$??++?D7D?=++DDDDDDDDDDDDDDDDDDDDDDD~~~~    //
//    MMMZ++=============I7?+=+7I+D==++DDDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    MMM$++==============7?++?Z7D=+DDDDDDDDDDDDDDDDDDDDDDDDDD:~~~    //
//    NMM7++==============$7OOI78DDDDDDD8DDDDDDDDDDDDDDDDDDDDD~~~~    //
//    MMMI++===============+DDDDDDDDDDZZZZODDDDDDDDDDDDDDDDDDD:~~~    //
//    MMMI++================DDDDDDDDDDZ$8D$DDDDDDDDDDDDDDDDDDD:~~~    //
//    MMM?+================DDDIII$DD?DZ7I$7ODDDDDDDDDDDDDDDDDD:~~~    //
//    MMMI++==============8DZ+==+IZD7OOZ7I8Z8DDDDDDDDDDDDDDDDD:~~~    //
//    MMMI++=============ODD?===+I7DDODO$$$7DDDDDDDDDDDDDDDDDD~~~~    //
//    NMM+++============DDDO?===?IDDD8Z$ZODDDDNDDDDDDDDDDDDDDD~~~~    //
//    MMM?++=+=========DDDDO+==+?$DDDD=~~?D8DDDDDDDDDDDDDDDDDD~~~~    //
//    NMN?+++=========8DDDD$+==+8DDDD$~=~=I78DDDDDDDDDDDDDDDDD~~~~    //
//    MMMI+++========+8DDDDI+==?DDDDZ=++=I~=I8DDDDDDDDDDDDDDDD~~~~    //
//    MMM?+++=======ZZDDDDZ?==+DDDD?III=Z$+???IODDDDDDDDDDDDDD:~~~    //
//    MMM?+++=======+DDDDD7+++7DDDDIZO$I?7??I?I78DDDDDDDDDDDDD~~~~    //
//    MMN?+++++======DDDDOI=+IDDDDII?Z$I?7ZZII??ZDDDDDDDDDDDDD~~~~    //
//    NMM?+++++++=+==+DDD$?+IDDDDD+=DOZ=II$O87+?888DDDDDDDDDDD~~~~    //
//    MNM??+++++++++=+DDZ7+?8DDDDD+IDDOZ$7Z88IIO8D8ZDDDDDDDDDD~~~~    //
//    MMDI??++++++++++DZ77IZDDDDDD++7DOZ$$ZOO=?OOD+ODDDDDDDDDD~~~~    //
//    MMNI?????++++++$O$$$ODDDDDDD??7DDOZ$ZOOOZ788D8?DDDDDDDDD~~~~    //
//    MMM$????+++++7$8OZZODDDDDDDD??I?D8OZZOIDOO87D$DDDDDDDDDD=~~~    //
//    MMMI??????+?ZOOOOZ8DDDDDDDND7??8ID8Z+Z$DOOZ88DDDDDDDDDDD~~~~    //
//    MMMO???????OO888DDDDDDDDDDDDD???DD+$=OO8DOOO8DDDDDDDDDDD~~~~    //
//    MMMDIII???O8O8DDDDDD8DDDDDDDDIIIDDDD88OODOOOODDD8NDDDDDD~~~~    //
//    MMMOIIIIII88ZZDDDDD88DODDDDDDIIIDDDDDDDZ8D88DDDDODDDDDDD~~:~    //
//    MMND8NMMNDNNMINMNMMDNNN8DMNDMDMN:~~~:~~::::::::~:~~~~::::~~~    //
//    DM8IMNMMMMNMNMMMMMMMMNNMMMMMMMNM~~~::::::::::::::::::::~~~~:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMZMNMMMMM=~~::::::::::::::::::::~~~~:    //
//    M8NNMMMMMMMMMMMMMMMMMMMM8MMMMMMD=~~:::::::::::::::::::::~~~:    //
//    DD8DMMMMMMMMMMMMMMMMNMMMDMMMMMM=~~~~:::::::::::::::::::~~~~~    //
//    $NO$8NMNMMMMMMMMMMMMMMMMMMMMMMM=~~~~::::::::::::::::::~:~~~=    //
//    MMNO8NNMNMMMMMMMMMMMMMMMMMMMMMM~~~~:::::::::::::::::::::~~~I    //
//    NON7DDNMMMMMMMMMMMNMMMMMMMMMMMM~~~~~:::::::::::::::::~~~~~~Z    //
//    Z8ZZ8$OMMMMMMMMMMMMMMMMMMMMMMMN~~~~~~::::::::::::~~~~~~~~~~O    //
//    =~==,+?$NMNMMMMMMMMMNNMMMMMMNMN~+~~~~~~~~~~~~~~~~~~~~~~~~~~N    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract SYZ is ERC721Creator {
    constructor() ERC721Creator("SYZYGY", "SYZ") {}
}
