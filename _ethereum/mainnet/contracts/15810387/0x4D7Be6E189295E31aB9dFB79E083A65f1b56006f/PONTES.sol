
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pontes_NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    My digital works as a multidisciplinary artist    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract PONTES is ERC721Creator {
    constructor() ERC721Creator("Pontes_NFT", "PONTES") {}
}
