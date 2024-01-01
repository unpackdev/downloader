// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Star Is Born
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//     SSS   AA  W     W U   U L     AA  K  K           N   N  AA  H  H III DDD      //
//    S     A  A W     W U   U L    A  A K K            NN  N A  A H  H  I  D  D     //
//     SSS  AAAA W  W  W U   U L    AAAA KK    v v  ss  N N N AAAA HHHH  I  D  D     //
//        S A  A  W W W  U   U L    A  A K K   v v  s   N  NN A  A H  H  I  D  D     //
//    SSSS  A  A   W W    UUU  LLLL A  A K  K   v  ss   N   N A  A H  H III DDD      //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract NAHID is ERC721Creator {
    constructor() ERC721Creator("A Star Is Born", "NAHID") {}
}
