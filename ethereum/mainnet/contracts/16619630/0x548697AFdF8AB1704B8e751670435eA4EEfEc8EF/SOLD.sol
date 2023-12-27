
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Moto Animals
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    The art of being unique 🍀      //
//                                    //
//                                    //
////////////////////////////////////////


contract SOLD is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Moto Animals", "SOLD") {}
}
