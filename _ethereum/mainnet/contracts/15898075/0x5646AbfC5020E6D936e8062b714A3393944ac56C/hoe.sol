
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: history of eternity
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    ---                                                                //
//                                                                       //
//    the two verbs “procreate” and “preserve” are synonyms in heaven    //
//                                                                       //
//    ---                                                                //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract hoe is ERC721Creator {
    constructor() ERC721Creator("history of eternity", "hoe") {}
}
