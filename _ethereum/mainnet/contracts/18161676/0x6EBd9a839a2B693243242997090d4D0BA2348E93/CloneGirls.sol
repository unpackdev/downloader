// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CloneGirls Tour commemorative NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    CloneGirls    //
//                  //
//                  //
//////////////////////


contract CloneGirls is ERC721Creator {
    constructor() ERC721Creator("CloneGirls Tour commemorative NFT", "CloneGirls") {}
}
