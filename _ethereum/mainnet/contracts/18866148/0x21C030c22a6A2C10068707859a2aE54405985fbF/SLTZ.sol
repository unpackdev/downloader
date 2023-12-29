// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JerrySaltz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Jerry    //
//             //
//             //
/////////////////


contract SLTZ is ERC721Creator {
    constructor() ERC721Creator("JerrySaltz", "SLTZ") {}
}
