
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ferix
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     .d888                 d8b                //
//    d88P"                  Y8P                //
//    888                                       //
//    888888 .d88b.  888d888 888 888  888       //
//    888   d8P  Y8b 888P"   888 `Y8bd8P'       //
//    888   88888888 888     888   X88K         //
//    888   Y8b.     888     888 .d8""8b.       //
//    888    "Y8888  888     888 888  888 88    //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract FRX is ERC721Creator {
    constructor() ERC721Creator("Ferix", "FRX") {}
}
