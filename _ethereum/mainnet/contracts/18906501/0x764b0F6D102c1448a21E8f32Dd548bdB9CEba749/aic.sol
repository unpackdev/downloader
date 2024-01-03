// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: arami icon
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    arami icon collection    //
//                             //
//                             //
/////////////////////////////////


contract aic is ERC1155Creator {
    constructor() ERC1155Creator("arami icon", "aic") {}
}
