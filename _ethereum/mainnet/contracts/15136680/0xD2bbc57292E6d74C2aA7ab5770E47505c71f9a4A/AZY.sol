
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    atriple    //
//               //
//               //
///////////////////


contract AZY is ERC721Creator {
    constructor() ERC721Creator("New contract", "AZY") {}
}
