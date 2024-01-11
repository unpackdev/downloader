
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbirdss
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Moonbirds    //
//                 //
//                 //
/////////////////////


contract MOONBIRDS is ERC721Creator {
    constructor() ERC721Creator("Moonbirdss", "MOONBIRDS") {}
}
