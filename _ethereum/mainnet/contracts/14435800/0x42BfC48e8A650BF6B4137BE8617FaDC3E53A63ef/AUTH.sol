
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ERC20
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    ERC20    //
//             //
//             //
/////////////////


contract AUTH is ERC721Creator {
    constructor() ERC721Creator("ERC20", "AUTH") {}
}
