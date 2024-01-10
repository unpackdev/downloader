
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XOX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    XOX    //
//           //
//           //
///////////////


contract XOX is ERC721Creator {
    constructor() ERC721Creator("XOX", "XOX") {}
}
