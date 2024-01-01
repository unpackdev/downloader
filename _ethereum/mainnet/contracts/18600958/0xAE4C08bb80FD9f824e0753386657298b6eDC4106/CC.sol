// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conscience
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Hello...    //
//                //
//                //
////////////////////


contract CC is ERC1155Creator {
    constructor() ERC1155Creator("Conscience", "CC") {}
}
