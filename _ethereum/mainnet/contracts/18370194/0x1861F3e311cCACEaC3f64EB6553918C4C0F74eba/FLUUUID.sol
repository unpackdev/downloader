// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLUUUID
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    qualquer coisa     //
//                       //
//                       //
///////////////////////////


contract FLUUUID is ERC1155Creator {
    constructor() ERC1155Creator("FLUUUID", "FLUUUID") {}
}
