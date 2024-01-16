
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VB PoStweet
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    PoS-tweet by Vitalik Buterin after the     //
//    succesful merge of the ETH blockchain      //
//    to go from PoW to PoS!                     //
//                                               //
//    - 09-15-2022                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract PoStweet is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
