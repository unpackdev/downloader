// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snapshots
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     _ ._   _. ._   _ |_   _ _|_  _    //
//    _> | | (_| |_) _> | | (_) |_ _>    //
//               |                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract SNAP is ERC721Creator {
    constructor() ERC721Creator("Snapshots", "SNAP") {}
}
