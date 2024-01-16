
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OM by 6529 - Day 1
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?#@@@@@@@@@@YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJJPGGGGGG&@@@@@@@@@&BGGGGGGYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJ?&@@@@@@&PGGGGGGGGG@@@@@@@5JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJJJJ5&&&#######BGGGGGGGGGG#######&&&BJJJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJYYYG@@@#GGGGGGGGGGGGGGGGGGGGGGGG@@@&YYYYJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJJJJJ&@@@GBBGGGGGGGGGGGGGGGGGGGGGGGGGGBG#@@@5JJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJJ5GGG&@@&GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB@@@BGGPJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJJJ?G@@@#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@&JJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ#&&&###BGGGGGG&@@@@@@@@@@@@@@@@@@@@@@@@BGGGGGG####&&&PJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGGGGGGBBG&@@@@@@@@@@@@@@@@@@@@@@@@BGBGGGGGGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGGGGGB@@@Y^~~~~~~~~~~~~~~~~~~~~~~~&@@&GGGGGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG#######5JJJJJJJJJJJJY!^^^JJJJJJY@@@@###BGG#@@@GJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG@@@&:::#@@@@@@@@@@@@@P::^@@@@@@@@@@@@@@#GG#@@@G?JJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJP&&&####GGG@@@@###@@@@JJJJJJY@@@&###@@@#JJJJJJG@@@BGGB###&&&#JJJJJJJJJJJJJJ    //
//    JJJJJJJJJJB@@@BGGGBBG&@@@@@@@@@&::::::^@@@@@@@@@@G.::::.J@@@#GBGGGG@@@@JJJJJJJJJJJJJJ    //
//    JJJJJJJJJJB@@@BGG#@@@J~~~~~~#@@&::::::^@@@G~~!@@@G.::::.J@@@@@@@GGG@@@@JJJJJJJJJJJJJJ    //
//    JJJJJJJJJJB@@@BGG#@@@?:^^^^:#@@@JJJJJJY@@@P:^~@@@#JJJJJJG@@@@@@@GGG@@@@JJJJJJJJJJJJJJ    //
//    JJJJJJJJJ?G@@@BGG#@@@?::^^^:#@@@@@@@@@@@@@G:^~@@@@@@@@@@@@@@@@@@GGG@@@@JJJJJJJJJJJJJJ    //
//    JJJJJJY#&&&###&&&@@@@&##G^^^7YYYYYYYYYYYYY7^^^JJJJYYYYYJG@@@@@@@&&@&###&&&PJJJJJJJJJJ    //
//    JJJJJJY@@@&PGG@@@@@@@@@@&^^^^:::::::::::::^~~~~~~^::::::J@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&GGG@@@@@@@@@@&??J~^^^^^^^^^^^^:P@@@@@@G:^^^^:J@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&GGG@@@@@@@@@@&JJJ7~~~^^^^^^^^^^Y######5^^^~~~5@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&GGG@@@@@@@@@@&JJJJJJ?^^^^^^^^^^^::::::^^^^?JJG@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&GGG@@@@@@@@@@&JJJJJJJ777777777777777777777JJ?G@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&GGG@@@@@@@@@@&JJJJJJJJJJJJJJYYYYYYYYYYYJJJJJ?G@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY@@@&PGG@@@@@@@@@@&JJJJJJJJJJJ??J&&&&&&&&&&BJJJJJ?G@@@@@@@@@@#GGB@@@BJJJJJJJJJJ    //
//    JJJJJJY#&&&###&&&@@@@@@@&777?JJJJJJ5GGG##########GJJJJJ?G@@@@@@@&&@&###&&&PJJJJJJJJJJ    //
//    JJJJJJJJJ?G@@@BGG#@@@@@@&^^^7JJJJJ?&@@@J?JJJJJJJJJJJJJJ?G@@@@@@@PGP@@@@JJJJJJJJJJJJJJ    //
//    JJJJJJJJJJB@@@BGG#@@@@@@&^^^~!~!JJJ5GGPJJJJJJJJJJJJJJ#&&@@@@&##&@@@BGGGJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJG@@@#GG#@@@@@@&^^^^^^^?J?JYJYYYYYYYYYYYYYYY@@@@@@@#GG#@@@P?JJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJYYYY@@@&GBG@@@&^^^^^^^^^^G@@@@@@@@@@@@@@@@@@@@@GGG@@@&YYYYJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG@@@&^^^^^^^^^:B@@@@@@@@@@@@@@@@@&&@&###&&&#JJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG@@@&^^^^^^^^^:B@@@@@@@@@@GPGGGGGGGP#@@@PJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG@@@&^^^^^^^^^:B@@@@@@&###&@&&&&&&&@&GGGYJJJJJJJJJJJJJJJJJJJJJJJJ    //
//    JJJJJJJJJJJJJJ@@@@GGG@@@&^^^^^^^^^:B@@@@@@&PGG@@@@@@@@@@&?JJJJJJJJJJJJJJJJJJJJJJJJJJJ    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract O6529 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
