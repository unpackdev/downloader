// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FANCollection_TOYONAKA2023
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//          ^          //
//         / \         //
//        / _ \        //
//       | / \ |       //
//       ||   ||       //
//       ||   ||       //
//       ||   ||       //
//      | |   | |      //
//     | |     | |     //
//    | |       | |    //
//                     //
//                     //
//                     //
/////////////////////////


contract FAN is ERC1155Creator {
    constructor() ERC1155Creator("FANCollection_TOYONAKA2023", "FAN") {}
}
