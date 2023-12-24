// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Another World 1/1 Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//     ANOTHER      //
//      WORLD       //
//       1/1        //
//    COLLECTION    //
//                  //
//                  //
//////////////////////


contract AnotherWorld is ERC721Creator {
    constructor() ERC721Creator("Another World 1/1 Collection", "AnotherWorld") {}
}
