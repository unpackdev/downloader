
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cardinal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//      _____ _   _     //
//     |_   _| \ | |    //
//       | | |  \| |    //
//       | | | |\  |    //
//       |_| |_| \_|    //
//                      //
//                      //
//                      //
//                      //
//////////////////////////


contract CRD is ERC721Creator {
    constructor() ERC721Creator("Cardinal", "CRD") {}
}
