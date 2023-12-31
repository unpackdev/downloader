// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ilona Jahkola Art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Ilona Jahkola Art    //
//                         //
//                         //
/////////////////////////////


contract IJA is ERC1155Creator {
    constructor() ERC1155Creator("Ilona Jahkola Art", "IJA") {}
}
