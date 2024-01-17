
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pinkdom by Selliset
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    .d88888b   88888888b dP        dP        dP .d88888b   88888888b d888888P     //
//    88.    "'  88        88        88        88 88.    "'  88           88        //
//    `Y88888b. a88aaaa    88        88        88 `Y88888b. a88aaaa       88        //
//          `8b  88        88        88        88       `8b  88           88        //
//    d8'   .8P  88        88        88        88 d8'   .8P  88           88        //
//     Y88888P   88888888P 88888888P 88888888P dP  Y88888P   88888888P    dP        //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract Selli is ERC721Creator {
    constructor() ERC721Creator("Pinkdom by Selliset", "Selli") {}
}
