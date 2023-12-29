// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monthly Drop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    M   M  OOO  N   N TTTTT H   H L   Y   Y    DDD  RRRR  OOO  PPP       //
//    MM MM O   O NN  N   T   H   H L    Y Y     D   D R   R O   O P  P    //
//    M M M O   O N N N   T   HHHHH L     Y      D   D RRRR  O   O PPP     //
//    M   M O   O N  NN   T   H   H L     Y      D   D R  R  O   O P       //
//    M   M  OOO  N   N   T   H   H LLLL  Y      DDD  R   R  OOO  P        //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract MONTHLY is ERC721Creator {
    constructor() ERC721Creator("Monthly Drop", "MONTHLY") {}
}
