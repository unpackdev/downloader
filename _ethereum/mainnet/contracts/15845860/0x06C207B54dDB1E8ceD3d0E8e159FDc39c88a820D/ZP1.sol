
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Up High
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    An open edition for 'Up High'    //
//                                     //
//                                     //
/////////////////////////////////////////


contract ZP1 is ERC721Creator {
    constructor() ERC721Creator("Up High", "ZP1") {}
}
