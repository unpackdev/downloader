// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jorge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Jorge    //
//             //
//             //
/////////////////


contract Jorge is ERC721Creator {
    constructor() ERC721Creator("Jorge", "Jorge") {}
}
