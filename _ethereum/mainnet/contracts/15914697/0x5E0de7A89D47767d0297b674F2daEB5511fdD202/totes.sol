
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: totes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//             _        _                           //
//         _  | |_ ___ | |_ ___  ___   _            //
//        (_) | __/ _ \| __/ _ \/ __| (_)           //
//     _   _  | || (_) | ||  __/\__ \  _   _        //
//    (_) (_)  \__\___/ \__\___||___/ (_) (_)       //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract totes is ERC721Creator {
    constructor() ERC721Creator("totes", "totes") {}
}
