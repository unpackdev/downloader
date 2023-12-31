// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mick 1of1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//          ___                       ___           ___          //
//         /\__\          ___        /\  \         /\__\         //
//        /::|  |        /\  \      /::\  \       /:/  /         //
//       /:|:|  |        \:\  \    /:/\:\  \     /:/__/          //
//      /:/|:|__|__      /::\__\  /:/  \:\  \   /::\__\____      //
//     /:/ |::::\__\  __/:/\/__/ /:/__/ \:\__\ /:/\:::::\__\     //
//     \/__/~~/:/  / /\/:/  /    \:\  \  \/__/ \/_|:|~~|~        //
//           /:/  /  \::/__/      \:\  \          |:|  |         //
//          /:/  /    \:\__\       \:\  \         |:|  |         //
//         /:/  /      \/__/        \:\__\        |:|  |         //
//         \/__/                     \/__/         \|__|         //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract MICK is ERC721Creator {
    constructor() ERC721Creator("Mick 1of1", "MICK") {}
}
