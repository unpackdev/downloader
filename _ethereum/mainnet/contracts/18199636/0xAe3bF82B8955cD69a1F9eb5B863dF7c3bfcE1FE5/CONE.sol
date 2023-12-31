// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: r/Coneheads
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//        /\        //
//       /  \       //
//      /----\      //
//     /      \     //
//    /________\    //
//                  //
//                  //
//////////////////////


contract CONE is ERC1155Creator {
    constructor() ERC1155Creator("r/Coneheads", "CONE") {}
}
