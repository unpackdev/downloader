// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SubliminalBOOM 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    SubliminalBOOM ART, contract 1    //
//                                      //
//                                      //
//////////////////////////////////////////


contract BOOM is ERC721Creator {
    constructor() ERC721Creator("SubliminalBOOM 1/1", "BOOM") {}
}
