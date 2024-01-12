
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karik
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    KDR    //
//           //
//           //
///////////////


contract KDR is ERC721Creator {
    constructor() ERC721Creator("Karik", "KDR") {}
}
