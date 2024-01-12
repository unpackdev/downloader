
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Archi-Tectonic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Archi-Tectonic by indie    //
//                               //
//                               //
///////////////////////////////////


contract ARTEC is ERC721Creator {
    constructor() ERC721Creator("Archi-Tectonic", "ARTEC") {}
}
