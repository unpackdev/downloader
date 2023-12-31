// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kyoken
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//     ┏┓  •   ┓ ┓        //
//     ┣┫┏┳┓╋┏┓┣┓┣┓┏┓     //
//     ┛┗┛┗┗┗┗┻┗┛┛┗┗┻     //
//                        //
//                        //
//                        //
//                        //
////////////////////////////


contract KYO8 is ERC721Creator {
    constructor() ERC721Creator("Kyoken", "KYO8") {}
}
