
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tester Contract
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////
//             //
//             //
//    test!    //
//             //
//             //
/////////////////


contract test is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
