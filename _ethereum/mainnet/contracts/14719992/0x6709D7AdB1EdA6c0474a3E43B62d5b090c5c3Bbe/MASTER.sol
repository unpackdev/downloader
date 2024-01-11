
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Masterworks by Frank Paulin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    MASTERWORKS BY FRANK PAULIN           //
//    IMAGES © BRUCE SILVERSTEIN GALLERY    //
//    ALL RIGHTS RESERVED                   //
//                                          //
//                                          //
//////////////////////////////////////////////


contract MASTER is ERC721Creator {
    constructor() ERC721Creator("Masterworks by Frank Paulin", "MASTER") {}
}
