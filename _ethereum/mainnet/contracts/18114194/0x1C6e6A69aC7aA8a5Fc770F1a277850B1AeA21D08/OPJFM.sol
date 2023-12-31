// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers for Founding Members
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    OPJ FOUNDING MEMBER    //
//                           //
//                           //
///////////////////////////////


contract OPJFM is ERC1155Creator {
    constructor() ERC1155Creator("Flowers for Founding Members", "OPJFM") {}
}
