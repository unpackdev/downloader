// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Muzik’s Single Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    d s   sb   sss.   sSSs.     //
//    S  S S S d       S          //
//    S   S  S Y      S           //
//    S      S   ss.  S           //
//    S      S      b S           //
//    S      S      P  S          //
//    P      P ` ss'    "sss'     //
//                                //
//                                //
//                                //
////////////////////////////////////


contract MSC is ERC721Creator {
    constructor() ERC721Creator(unicode"Muzik’s Single Contract", "MSC") {}
}
