// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Inner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//      __  __ _  __ _  ____  ____     //
//     (  )(  ( \(  ( \(  __)(  _ \    //
//      )( /    //    / ) _)  )   /    //
//     (__)\_)__)\_)__)(____)(__\_)    //
//                                     //
//                                     //
/////////////////////////////////////////


contract INNER is ERC721Creator {
    constructor() ERC721Creator("Inner", "INNER") {}
}
