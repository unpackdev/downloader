// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kicked Out Homer
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    PhillyObie    //
//                  //
//                  //
//////////////////////


contract HMR is ERC1155Creator {
    constructor() ERC1155Creator("Kicked Out Homer", "HMR") {}
}
