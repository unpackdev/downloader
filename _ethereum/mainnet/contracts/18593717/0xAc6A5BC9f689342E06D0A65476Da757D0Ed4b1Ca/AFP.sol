// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art for Palestine
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//               ______                   //
//           .-'' ____ ''-.               //
//          /.-=""    ""=__\_________     //
//          |-===wwwwww|\ , , , , , /|    //
//          \'-=,,____,,\\ ` ' ` ' //     //
//           '-..______..\'._____.'/      //
//                   `'-----'`            //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract AFP is ERC1155Creator {
    constructor() ERC1155Creator("Art for Palestine", "AFP") {}
}
