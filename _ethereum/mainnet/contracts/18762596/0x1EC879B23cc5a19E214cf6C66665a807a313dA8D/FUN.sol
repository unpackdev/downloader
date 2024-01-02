// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Funny travel
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    FUNNY TRAVEL NFT    //
//                        //
//                        //
////////////////////////////


contract FUN is ERC1155Creator {
    constructor() ERC1155Creator("Funny travel", "FUN") {}
}
