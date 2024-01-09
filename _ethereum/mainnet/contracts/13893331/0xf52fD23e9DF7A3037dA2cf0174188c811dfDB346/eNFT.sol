
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Etopia Avatar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//         ETOPIA METAVERSE          //
//    visit us at: www.etopia.one    //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract eNFT is ERC721Creator {
    constructor() ERC721Creator("Etopia Avatar", "eNFT") {}
}
