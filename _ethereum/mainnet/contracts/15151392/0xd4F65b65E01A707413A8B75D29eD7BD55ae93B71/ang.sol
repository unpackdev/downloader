
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: angle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    ang    //
//           //
//           //
///////////////


contract ang is ERC721Creator {
    constructor() ERC721Creator("angle", "ang") {}
}
