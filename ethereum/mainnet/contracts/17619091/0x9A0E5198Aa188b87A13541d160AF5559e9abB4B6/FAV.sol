// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers and Vases
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    FLOWERS AND VASES    //
//                         //
//                         //
/////////////////////////////


contract FAV is ERC1155Creator {
    constructor() ERC1155Creator("Flowers and Vases", "FAV") {}
}
