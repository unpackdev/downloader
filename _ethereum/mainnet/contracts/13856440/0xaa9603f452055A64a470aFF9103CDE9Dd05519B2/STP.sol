
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strange Punks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    A Solemn Stranger Production    //
//                                    //
//                                    //
////////////////////////////////////////


contract STP is ERC721Creator {
    constructor() ERC721Creator("Strange Punks", "STP") {}
}
