
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KaijuFrenz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    KaijuFrenz    //
//                  //
//                  //
//////////////////////


contract KF is ERC721Creator {
    constructor() ERC721Creator("KaijuFrenz", "KF") {}
}
