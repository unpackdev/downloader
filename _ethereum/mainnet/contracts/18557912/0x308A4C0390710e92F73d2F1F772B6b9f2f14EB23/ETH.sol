// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BasedAF x Mira/Wandererkitty TP3 [GOLD]
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    TP3 [GOLD]    //
//                  //
//                  //
//////////////////////


contract ETH is ERC1155Creator {
    constructor() ERC1155Creator("BasedAF x Mira/Wandererkitty TP3 [GOLD]", "ETH") {}
}
