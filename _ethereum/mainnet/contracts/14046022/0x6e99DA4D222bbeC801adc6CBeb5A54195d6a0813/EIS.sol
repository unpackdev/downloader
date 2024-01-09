
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eisenetics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR******#RRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR**********#RRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRR@@RRRRRRRRRRRRRRRRR#*************@RRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRR@********@RRRRRRRRRRRR****************#RRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRR************@RRRRRRRRR******************#RRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRR***************RRRRRRR******#RRRRRR@******RRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRR*****************RRRRR******@RRRRRRRRR******RRRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRR#*****#RRRR#*******RRR#*****RRRRRRRRRRRR*****RRRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRR*****RRRRRRRR*******R@*****@RRRRRRRRRRRR#****@RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRR@****@RRRRRRRRR#*****#*****#RRRRRRRRRRRRRR****#RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRR*****RRRRRRRRRRR#*********#RRRRRRRRRRRRRRR*****RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRR****#RRRRRRRRRRRR#********RRRRRRRRRRRRRRRR#****RRRRRRRR***RRRRRRRR    //
//    RR@********#RR****@RRRRRRRRRRRRR*******RRRRRRRRRRRRRRRRR#****RR***************#R    //
//    RR@********#RR****@RRRRRRRRRRRRRR*****#RRRRRRRRRRRRRRRRR#****RR***************#R    //
//    RR@********#RR****#RRRRRRRRRRRRR*******RRRRRRRRRRRRRRRRR#****RR***************#R    //
//    RRRRRRRRRRRRRR*****RRRRRRRRRRRR*********RRRRRRRRRRRRRRRR#****RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRR*****RRRRRRRRRRR**********#RRRRRRRRRRRRRRR*****RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRR@*****RRRRRRRRR******#*****@RRRRRRRRRRRRRR****#RRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRR*****#RRRRRR@******#RR*****RRRRRRRRRRRRR#****RRRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRR@******#RR#********RRR#*****RRRRRRRRRRRR*****RRRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRRR#***************#RRRRR#*****@RRRRRRRRR******RRRRRRRRR***RRRRRRRR    //
//    RRRRRRRRRRRRRRRRR**************#RRRRRRR******#RRRRRR#******RRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRR#***********RRRRRRRRRR******************@RRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRR#******#RRRRRRRRRRRRR#***************@RRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#*************RRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#*********#RRRRRRRRRRRRRRRRRRRRRRRRR    //
//    RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR@****#RRRRRRRRRRRRRRRRRRRRRRRRRRRR    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract EIS is ERC721Creator {
    constructor() ERC721Creator("Eisenetics", "EIS") {}
}
