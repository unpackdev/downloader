// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JRNY CLUB COLLECTIBLES
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//     +-++-++-++-+ +-++-++-++-+ +-++-++-++-++-++-++-++-++-++-++-++-+    //
//     |J||R||N||Y| |C||L||U||B| |C||O||L||L||E||C||T||I||B||L||E||S|    //
//     +-++-++-++-+ +-++-++-++-+ +-++-++-++-++-++-++-++-++-++-++-++-+    //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract JCC is ERC1155Creator {
    constructor() ERC1155Creator("JRNY CLUB COLLECTIBLES", "JCC") {}
}
