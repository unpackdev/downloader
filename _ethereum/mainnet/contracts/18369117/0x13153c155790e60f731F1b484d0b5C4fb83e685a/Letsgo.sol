// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Privilege art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    art by Kalle Kallinski    //
//                              //
//                              //
//////////////////////////////////


contract Letsgo is ERC721Creator {
    constructor() ERC721Creator("New Privilege art", "Letsgo") {}
}
