// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LooksRare
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    -_-    //
//           //
//           //
///////////////


contract LOOKS is ERC721Creator {
    constructor() ERC721Creator("LooksRare", "LOOKS") {}
}
