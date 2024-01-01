// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collector Pass
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////
//               //
//               //
//    COLLECT    //
//               //
//               //
///////////////////


contract PASS is ERC1155Creator {
    constructor() ERC1155Creator("Collector Pass", "PASS") {}
}
