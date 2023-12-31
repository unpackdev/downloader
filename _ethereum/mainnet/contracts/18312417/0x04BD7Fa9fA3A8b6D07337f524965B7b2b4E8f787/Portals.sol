// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    Portals    //
//               //
//               //
///////////////////


contract Portals is ERC721Creator {
    constructor() ERC721Creator("Portals", "Portals") {}
}
