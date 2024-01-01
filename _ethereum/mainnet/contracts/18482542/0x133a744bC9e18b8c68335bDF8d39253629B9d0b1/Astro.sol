// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Astro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Astro    //
//             //
//             //
/////////////////


contract Astro is ERC721Creator {
    constructor() ERC721Creator("Astro", "Astro") {}
}
