
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phoebe Heess
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                  ._      _.                  //
//                 /  `""""`  \                 //
//            .-""`'-..____..-'`""-.            //
//          /`\       |    |       /`\          //
//        /`   |      |    |      |   `\        //
//       /`    |      |    |      |    `\       //
//      /      |                  |      \      //
//     /       /  N3RD COUTURE is \       \     //
//    /        |  a collection of |        \    //
//    '-._____.|   experiments,   |._____.-'    //
//             |   exploring the  |             //
//             |  convergence of  |             //
//             |   fashion with   |             //
//             \ the new artistic |             //
//             /    medium of     |             //
//             |  contract art    \             //
//             |                  |             //
//             '._              _.'             //
//                `""--------""`                //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract PHNC is ERC721Creator {
    constructor() ERC721Creator("Phoebe Heess", "PHNC") {}
}
