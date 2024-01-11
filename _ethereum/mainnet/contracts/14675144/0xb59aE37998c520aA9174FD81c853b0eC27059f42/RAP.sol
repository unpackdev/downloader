
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ROMbrandt Airdrop Pass
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ROMbrandt Editions Pass.                             //
//    Holders will receive monthly editions airdropped     //
//    to the wallet address holding this pass.             //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract RAP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
