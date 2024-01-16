
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Merge
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    HHHHHHHHHHHHHHHHHH@H@H@@H@@H@H@@@@H@@@@@@@H@@@@@H@@H@H@H@H@H    //
//    HH@HH@H@H@@H@@H@@@H@@H@H@@H@@@H@H@@@H@H@H@@H@@H@@@H@H@H@H@@H    //
//    HHH@@H@@H@H@HH@HMHMHH@HH@H@@M%.WH@H@@H@@@H@@@@@@H@@@@@H@H@H@    //
//    H@HHH@HH@H@H@HHHMM@H@H@@H@HM\` _WH@@@@H@H@@H@@H@@H@H@H@H@H@H    //
//    HH@HH@@H@@H@HH@@HHHH@H@M@@M^  .~(HHH@@@H@@H@MH@@H@@@H@@H@@H@    //
//    HH@H@HH@H@H@H@@@@H@@H@@HHM^```_:(+MH@H@@@H@HM@@H@H@H@@HH@HH@    //
//    H@HH@H@HHHHNH@HMM@H@HH@@M'````(<+1zMMHgH@@@@HHH@H@H@H@H@HHH@    //
//    HH@HH@@@H@HH@HHMM@HH@H@#'      .~~(zHMg@@@H@HH@HHH@H@H@@@@H@    //
//    H@H@@HH@@H@HH@H@HHH@HH#` .   ` ~~(jvzHM@H@@H@@@@H@@H@HH@HH@H    //
//    H@H@H@@H@@HHHH@H@H@H@@`` .~.``-~~jtzuZWHH@H@@@H@@HH@H@HH@HH@    //
//    HH@H@HH@HH@HH@H@HH@@D`` ...~.`_:+lrzuyyWH@@H@HH@H@H@MH@@H@HH    //
//    H@H@H@H@@H@H@H@HH@Mt``....~~~_(+ltrzuXVfWMH@H@@HH@@HHHMHHH@H    //
//    HH@HH@HH@HH@HH@H@M^``. ..~((gWWkkAwuZZfpppMHH@HH@HH@@HHHHHH@    //
//    HHH@HH@HH@HHH@@@#!``. (JTYYYTTWHHHHHHkWfpppMHHH@@HHH@HH@@HH@    //
//    HH@HH@H@HH@H@HHD_.._~~..~.~__~XHHWWyyyyyyVWWMHHHMH@@@MH@HH@H    //
//    HHH@HHHH@HH@HHMMaJJ-~~~_.....~dyyyyyyyyyWQgNMMMHHHHHHH@HH@H@    //
//    HH@HH@@HH@HH@HN,?OUHMMNgJ._...dZZyWQNMMMMMMMNMNMHHH@HHH@HH@H    //
//    HHHHHHHH@HHHH@HHx.?1OwwXWMMMNNNMMMMMMMERGEkNMMNHHHH@@HH@HHHH    //
//    HH@HHHHHHHH@HHHH@b `_1ttvzuuXUMMH@@H@@HHkkMMMNHHHHHHHH@HMHHH    //
//    HHHH@HHHHH@HHHHHHHN.``.?OrvvvzH@@gHHHHpbWMMMN#HHHH@HHHHHHH@H    //
//    HHHHHHHHHHHHHHHHHHHM,`.`.?ztttHkkkHffppWMMMNHHHHHHH@HHHHHHHH    //
//    HHHHHHHHHHHHHHHHHHHHHp`` ..(llpbbVyffpNMMMN#HHHHHHHHHHHHHHHH    //
//    HHHHHHHHHHHHHHHHHHHHHHh-~.~_1lpbWyyyVMMMM#HHHHHHHHHHHH@HHHHH    //
//    #####H#H#H##HHHHHHHHHHHN,.~~(=ppyyyWMMMN#HHHHHHHHHHHHHHHHHHH    //
//    N#M#############HHHHHHH#HL.._=WWyyqMMMM#HHHHHHHHHHHHHHHHHHH#    //
//    N######################HH#N,.(WVVdMMMNN#HHH#H#H#############    //
//    N#######################H##M,_VWMMMMMN#HHHH###M#############    //
//    NM#NNNNN#NNNNNNNN#########NNNmqMMMMMN###NNNN#####N#####NNNN#    //
//    NNNNNNNNNNNNNNNNNNNNN##NNNNNMMMMMMMNNNNNNNNNNNNNNNNNNNNNNN#N    //
//    MMMNMNNNNNNNNNNNNNNNNNNNNNMNMNMMNMMNMNNNNMNNMNNMNNNNNNNNNNNN    //
//    MMNMMNMNNNNMMNMNNMNMNNMMNMNMNNNNMNNMMNMNMNMNMMNMMMMMNNNNNNNN    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract TM is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
