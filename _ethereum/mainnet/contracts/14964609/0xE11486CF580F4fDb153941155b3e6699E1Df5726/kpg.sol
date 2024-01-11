
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kpgenesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//               ,--,    //
//         _ ___/ /\|    //
//     ,;'( )__, )  ~    //
//    //  //   '--;      //
//    '   \     | ^      //
//         ^    ^        //
//                       //
//                       //
///////////////////////////


contract kpg is ERC721Creator {
    constructor() ERC721Creator("kpgenesis", "kpg") {}
}
