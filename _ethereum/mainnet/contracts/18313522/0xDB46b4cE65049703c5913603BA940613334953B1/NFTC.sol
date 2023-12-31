// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT CAMPUS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    NFT CAMPUS Collection    //
//                             //
//                             //
//                             //
/////////////////////////////////


contract NFTC is ERC1155Creator {
    constructor() ERC1155Creator("NFT CAMPUS", "NFTC") {}
}
