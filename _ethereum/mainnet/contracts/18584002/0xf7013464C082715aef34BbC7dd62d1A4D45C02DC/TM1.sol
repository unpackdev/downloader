// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test memberships v1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//           |          //
//          / \         //
//         / _ \        //
//        |.o'.|        //
//        |'._.'|       //
//        |     |       //
//       ,'|  | |`.     //
//     /  |  | |  \     //
//    |,-'--|--'-. |    //
//    TESTER90000000    //
//                      //
//                      //
//////////////////////////


contract TM1 is ERC721Creator {
    constructor() ERC721Creator("test memberships v1", "TM1") {}
}
