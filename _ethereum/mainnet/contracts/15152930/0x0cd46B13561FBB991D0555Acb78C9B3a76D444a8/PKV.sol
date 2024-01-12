
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punksville
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    PKV    //
//           //
//           //
///////////////


contract PKV is ERC721Creator {
    constructor() ERC721Creator("Punksville", "PKV") {}
}
