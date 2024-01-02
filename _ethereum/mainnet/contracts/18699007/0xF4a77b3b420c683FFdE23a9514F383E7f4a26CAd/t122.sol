// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test-12-2
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    test_12_2    //
//                 //
//                 //
/////////////////////


contract t122 is ERC1155Creator {
    constructor() ERC1155Creator("test-12-2", "t122") {}
}
