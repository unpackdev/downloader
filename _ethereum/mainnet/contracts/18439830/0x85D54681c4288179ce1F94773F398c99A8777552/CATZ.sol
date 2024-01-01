// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cats
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Reactive Labs    //
//                     //
//                     //
/////////////////////////


contract CATZ is ERC1155Creator {
    constructor() ERC1155Creator("Cats", "CATZ") {}
}
