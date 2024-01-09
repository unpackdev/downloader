
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FFF
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//     (    (    (         //
//     )\ ) )\ ) )\ )      //
//    (()/((()/((()/(      //
//     /(_))/(_))/(_))     //
//    (_))_(_))_(_))_|     //
//    | |_ | |_ | |_       //
//    | __|| __|| __|      //
//    |_|  |_|  |_|        //
//                         //
//                         //
/////////////////////////////


contract FF is ERC721Creator {
    constructor() ERC721Creator("FFF", "FF") {}
}
