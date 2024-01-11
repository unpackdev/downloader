
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anonymous Nobody: Crème de la Crème
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//       _________       //
//      |__CREME__|      //
//     / \         \     //
//    /___\_________\    //
//    |   | \       |    //
//    |   |  \      |    //
//    |   |   \     |    //
//    |   |    \    |    //
//    |   |  A  \   |    //
//    |   |\     \  |    //
//    |   | \  F  \ |    //
//    |   |  \     \|    //
//    |   |   \  N  |    //
//    |   |    \    |    //
//    |   |     \   |    //
//    |   |      \  |    //
//    |___|_______\_|    //
//                       //
//                       //
///////////////////////////


contract CREME is ERC721Creator {
    constructor() ERC721Creator(unicode"Anonymous Nobody: Crème de la Crème", "CREME") {}
}
