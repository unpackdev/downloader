// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEW GENESIS - EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    more art     //
//                 //
//                 //
/////////////////////


contract GENED is ERC1155Creator {
    constructor() ERC1155Creator("NEW GENESIS - EDITIONS", "GENED") {}
}
