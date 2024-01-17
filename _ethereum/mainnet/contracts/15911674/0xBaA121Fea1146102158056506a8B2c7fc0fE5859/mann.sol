
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: man
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//    n others come to view your smart contract. The symbol is also used when sharing links to your smart contracts, and platforms where NFT sales and transfer activity are displayed.    //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract mann is ERC721Creator {
    constructor() ERC721Creator("man", "mann") {}
}
