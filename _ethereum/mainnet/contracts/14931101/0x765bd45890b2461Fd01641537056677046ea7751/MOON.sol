
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOON nft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    0101010101010101    //
//                        //
//                        //
////////////////////////////


contract MOON is ERC721Creator {
    constructor() ERC721Creator("MOON nft", "MOON") {}
}
