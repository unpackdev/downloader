// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Muscle Machines
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//    ==========================================================               ==========================================================    //
//    | SSSSSSSSS K      K EEEEEEEE TTTTTTTT CCCCCCCC H      H |     AAAAAA    | SSSSSSSSS K      K EEEEEEEE TTTTTTTT CCCCCCCC H      H |    //
//    | S         K    K   E           TT    C        H      H |     A    A    | S         K    K   E           TT    C        H      H |    //
//    | SSSSSSSSS KKKKK    EEEEEEE     TT    C        HHHHHHHH | --  A    A -- | SSSSSSSSS KKKKK    EEEEEEE     TT    C        HHHHHHHH |    //
//    |         S K    K   E           TT    C        H      H |    AAAAAAAA   |         S K    K   E           TT    C        H      H |    //
//    | SSSSSSSSS K      K EEEEEEEE    TT    CCCCCCCC H      H |    A      A   | SSSSSSSSS K      K EEEEEEEE    TT    CCCCCCCC H      H |    //
//    ==========================================================    A      A   ==========================================================    //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SASMM is ERC721Creator {
    constructor() ERC721Creator("Muscle Machines", "SASMM") {}
}
