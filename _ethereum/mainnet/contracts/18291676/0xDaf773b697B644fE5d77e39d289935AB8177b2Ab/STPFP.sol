// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shitty Trash PFPs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    STPFP    //
//             //
//             //
/////////////////


contract STPFP is ERC721Creator {
    constructor() ERC721Creator("Shitty Trash PFPs", "STPFP") {}
}
