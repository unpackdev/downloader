
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LRD/BZL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                           AW                                                    //
//    `7MMF'          `7MM"""Mq.      `7MM"""Yb.            ,M'     `7MM"""Yp,     MMM"""AMV     `7MMF'            //
//      MM              MM   `MM.       MM    `Yb.          MV        MM    Yb     M'   AMV        MM              //
//      MM              MM   ,M9        MM     `Mb         AW         MM    dP     '   AMV         MM              //
//      MM              MMmmdM9         MM      MM        ,M'         MM"""bg.        AMV          MM              //
//      MM      ,       MM  YM.         MM     ,MP        MV          MM    `Y       AMV   ,       MM      ,       //
//      MM     ,M       MM   `Mb.       MM    ,dP'       AW           MM    ,9      AMV   ,M       MM     ,M       //
//    .JMMmmmmMMM     .JMML. .JMM.    .JMMmmmdP'        ,M'         .JMMmmmd9      AMVmmmmMM     .JMMmmmmMMM       //
//                                                      MV                                                         //
//                                                     AW                                                          //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract lrdbzl is ERC721Creator {
    constructor() ERC721Creator("LRD/BZL", "lrdbzl") {}
}
