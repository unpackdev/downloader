// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Slugs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    .|'''|  '||     '||   ||` .|'''''| .|'''|      //
//    ||       ||      ||   ||  || .     ||          //
//    `|'''|,  ||      ||   ||  || |''|| `|'''|,     //
//     .   ||  ||      ||   ||  ||    ||  .   ||     //
//     |...|' .||...|  `|...|'  `|....|'  |...|'     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SLUGS is ERC721Creator {
    constructor() ERC721Creator("The Slugs", "SLUGS") {}
}
