// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digi Tickets
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//        _/_/_/    _/_/_/    _/_/_/  _/_/_/       //
//       _/    _/    _/    _/          _/          //
//      _/    _/    _/    _/  _/_/    _/           //
//     _/    _/    _/    _/    _/    _/            //
//    _/_/_/    _/_/_/    _/_/_/  _/_/_/           //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract DGT is ERC1155Creator {
    constructor() ERC1155Creator("Digi Tickets", "DGT") {}
}
