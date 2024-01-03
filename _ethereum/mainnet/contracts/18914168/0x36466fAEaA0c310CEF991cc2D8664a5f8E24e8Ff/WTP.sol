// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MTP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//      _            //
//     _( )_         //
//    (     (o___    //
//     |      _ 7    //
//      \    (")     //
//      /     \ \    //
//     |    \ __/    //
//     |        |    //
//     (       /     //
//      \     /      //
//       )   /(_     //
//       |  (___)    //
//        \___)      //
//                   //
//                   //
///////////////////////


contract WTP is ERC721Creator {
    constructor() ERC721Creator("MTP", "WTP") {}
}
