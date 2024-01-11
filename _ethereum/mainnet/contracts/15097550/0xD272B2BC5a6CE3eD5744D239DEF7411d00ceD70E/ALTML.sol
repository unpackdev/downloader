
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alhucard Timeless Derivatives
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//    This is the official contract for Alhucard Timeless Derivatives.                 //
//    These are an artistic derivative of the Timeless characters created by Viii.     //
//                                                                                     //
//    We love Treeverse!                                                               //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract ALTML is ERC721Creator {
    constructor() ERC721Creator("Alhucard Timeless Derivatives", "ALTML") {}
}
