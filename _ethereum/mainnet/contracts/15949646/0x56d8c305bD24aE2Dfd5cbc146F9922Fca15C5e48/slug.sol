
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: just physicals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//        .----.   @   @    //
//       / .-"-.`.  \v/     //
//       | | '\ \ \_/ )     //
//     ,-\ `-.' /.'  /      //
//    '---`----'----'       //
//                          //
//                          //
//////////////////////////////


contract slug is ERC721Creator {
    constructor() ERC721Creator("just physicals", "slug") {}
}
