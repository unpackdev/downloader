// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flavio Reber Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    Flavio Reber Editions minted on Manifold    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RF is ERC1155Creator {
    constructor() ERC1155Creator("Flavio Reber Editions", "RF") {}
}
