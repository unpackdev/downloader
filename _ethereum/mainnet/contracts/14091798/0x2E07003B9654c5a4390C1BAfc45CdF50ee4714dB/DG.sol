
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DigiGenesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract DG is ERC721Creator {
    constructor() ERC721Creator("DigiGenesis", "DG") {}
}
