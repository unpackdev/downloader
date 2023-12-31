// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One on One
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//         _                 _         //
//        / |   ___  _ __   / |        //
//        | |  / _ \| '_ \  | |        //
//        | | | (_) | | | | | |        //
//        |_|  \___/|_| |_| |_|        //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract oOo is ERC721Creator {
    constructor() ERC721Creator("One on One", "oOo") {}
}
