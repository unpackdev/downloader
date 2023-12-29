// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Curiosa
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    -.-. ..- .-. .. --- ... .-     //
//                                   //
//                                   //
///////////////////////////////////////


contract CURIO is ERC1155Creator {
    constructor() ERC1155Creator("Curiosa", "CURIO") {}
}
