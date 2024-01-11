
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tynezphoto
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    PLUSH    //
//             //
//             //
/////////////////


contract PLUSH is ERC721Creator {
    constructor() ERC721Creator("Tynezphoto", "PLUSH") {}
}
