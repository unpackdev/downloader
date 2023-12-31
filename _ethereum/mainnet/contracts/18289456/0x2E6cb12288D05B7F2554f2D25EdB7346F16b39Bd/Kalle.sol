// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Showroom by Kalle Kallinski
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    Kallinski will help and present his artworks for         //
//    the complete Nftcommunity and for everybody, the will    //
//    be accept art                                            //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract Kalle is ERC1155Creator {
    constructor() ERC1155Creator("Showroom by Kalle Kallinski", "Kalle") {}
}
