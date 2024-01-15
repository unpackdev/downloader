
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SELF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//     (         (     (         //
//     )\ )      )\ )  )\ )      //
//    (()/( (   (()/( (()/(      //
//     /(_)))\   /(_)) /(_))     //
//    (_)) ((_) (_))  (_))_|     //
//    / __|| __|| |   | |_       //
//    \__ \| _| | |__ | __|      //
//    |___/|___||____||_|        //
//                               //
//                               //
//                               //
///////////////////////////////////


contract SELF is ERC721Creator {
    constructor() ERC721Creator("SELF", "SELF") {}
}
