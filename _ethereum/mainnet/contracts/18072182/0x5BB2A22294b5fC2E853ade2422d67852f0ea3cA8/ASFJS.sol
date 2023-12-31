// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Another summer in France
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//     AA  N   N  OOO  TTTTTT H  H EEEE RRRR       SSS  U   U M   M M   M EEEE RRRR      //
//    A  A NN  N O   O   TT   H  H E    R   R     S     U   U MM MM MM MM E    R   R     //
//    AAAA N N N O   O   TT   HHHH EEE  RRRR       SSS  U   U M M M M M M EEE  RRRR      //
//    A  A N  NN O   O   TT   H  H E    R R           S U   U M   M M   M E    R R       //
//    A  A N   N  OOO    TT   H  H EEEE R  RR     SSSS   UUU  M   M M   M EEEE R  RR     //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract ASFJS is ERC721Creator {
    constructor() ERC721Creator("Another summer in France", "ASFJS") {}
}
