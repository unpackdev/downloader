
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FIRMAMENTO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    DDD  EEEE BBBB   OOO  RRRR   AA      H  H III RRRR   SSS   CCC H  H     //
//    D  D E    B   B O   O R   R A  A     H  H  I  R   R S     C    H  H     //
//    D  D EEE  BBBB  O   O RRRR  AAAA     HHHH  I  RRRR   SSS  C    HHHH     //
//    D  D E    B   B O   O R R   A  A     H  H  I  R R       S C    H  H     //
//    DDD  EEEE BBBB   OOO  R  RR A  A     H  H III R  RR SSSS   CCC H  H     //
//                                                                            //
//                                                                            //
//        FFFF III RRRR  M   M  AA  M   M EEEE N   N TTTTTT  OOO              //
//        F     I  R   R MM MM A  A MM MM E    NN  N   TT   O   O             //
//        FFF   I  RRRR  M M M AAAA M M M EEE  N N N   TT   O   O             //
//        F     I  R R   M   M A  A M   M E    N  NN   TT   O   O             //
//        F    III R  RR M   M A  A M   M EEEE N   N   TT    OOO              //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract FIR is ERC721Creator {
    constructor() ERC721Creator("FIRMAMENTO", "FIR") {}
}
