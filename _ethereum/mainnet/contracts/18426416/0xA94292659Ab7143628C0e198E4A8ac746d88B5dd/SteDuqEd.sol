// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stephan Duquesnoy Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    /////////////////////////////    //
//    //                         //    //
//    //                         //    //
//    //    Stephan Duquesnoy    //    //
//    //    ERC 721 Editions     //    //
//    //                         //    //
//    /////////////////////////////    //
//                                     //
//                                     //
/////////////////////////////////////////


contract SteDuqEd is ERC721Creator {
    constructor() ERC721Creator("Stephan Duquesnoy Editions", "SteDuqEd") {}
}
