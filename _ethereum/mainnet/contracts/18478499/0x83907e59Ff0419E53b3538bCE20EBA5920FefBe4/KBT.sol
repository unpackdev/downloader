// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KILLABITS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    KILLABITS is the pixel companion collection to the KILLABEARS.  A collection of 3,333 thoughtfully designed NFTs on the Ethereum Blockchain.    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KBT is ERC721Creator {
    constructor() ERC721Creator("KILLABITS", "KBT") {}
}
