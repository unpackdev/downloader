// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testburn2
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////
//             //
//             //
//    burn2    //
//             //
//             //
/////////////////


contract burn2 is ERC1155Creator {
    constructor() ERC1155Creator("testburn2", "burn2") {}
}
