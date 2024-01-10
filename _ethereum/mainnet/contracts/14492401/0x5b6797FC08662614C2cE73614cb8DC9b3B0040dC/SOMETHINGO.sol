
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Something Official
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    AZUKI    //
//             //
//             //
/////////////////


contract SOMETHINGO is ERC721Creator {
    constructor() ERC721Creator("Something Official", "SOMETHINGO") {}
}
