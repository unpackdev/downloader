// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cr0b
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      .,-::::: :::::::..           :::::::.          //
//    ,;;;'````' ;;;;``;;;;    ,;;,   ;;;'';;'         //
//    [[[         [[[,/[[['  ,['  [n  [[[__[[\.        //
//    $$$         $$$$$$c    $$    $$ $$""""Y$$        //
//    `88bo,__,o, 888b "88bo,Y8,  ,8"_88o,,od8P        //
//      "YUMMMMMP"MMMM   "W"  "YmmP  ""YUMMMP"         //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract cr0b is ERC721Creator {
    constructor() ERC721Creator("cr0b", "cr0b") {}
}
