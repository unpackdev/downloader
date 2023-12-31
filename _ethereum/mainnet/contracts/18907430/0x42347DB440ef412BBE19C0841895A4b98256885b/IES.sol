// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ignis Elite
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//    ┳    •   ┏┓┓•       //
//    ┃┏┓┏┓┓┏  ┣ ┃┓╋┏┓    //
//    ┻┗┫┛┗┗┛  ┗┛┗┗┗┗     //
//      ┛                 //
//                        //
//                        //
//                        //
////////////////////////////


contract IES is ERC1155Creator {
    constructor() ERC1155Creator("Ignis Elite", "IES") {}
}
