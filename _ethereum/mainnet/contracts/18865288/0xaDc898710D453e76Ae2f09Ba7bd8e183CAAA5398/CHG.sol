// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Christmas gift
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    CHG    //
//           //
//           //
///////////////


contract CHG is ERC721Creator {
    constructor() ERC721Creator("Christmas gift", "CHG") {}
}
