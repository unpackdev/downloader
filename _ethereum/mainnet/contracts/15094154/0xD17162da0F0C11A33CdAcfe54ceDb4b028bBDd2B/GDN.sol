
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gdn contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    gdn    //
//           //
//           //
///////////////


contract GDN is ERC721Creator {
    constructor() ERC721Creator("gdn contract", "GDN") {}
}
