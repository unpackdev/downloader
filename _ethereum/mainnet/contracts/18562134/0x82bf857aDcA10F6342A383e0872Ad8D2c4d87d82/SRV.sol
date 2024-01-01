// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Survive
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    SURVIVING THE BEAR WINTER    //
//                                 //
//                                 //
/////////////////////////////////////


contract SRV is ERC1155Creator {
    constructor() ERC1155Creator("Survive", "SRV") {}
}
