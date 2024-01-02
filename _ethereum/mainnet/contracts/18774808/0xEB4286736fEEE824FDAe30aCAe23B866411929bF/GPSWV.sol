// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gypsy Waves
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//        ┓     •     ┏┓     ┓        //
//        ┣┓┓┏  ┓┏┳┓┏┓┃┫┓┏┏┓┏┫        //
//        ┗┛┗┫  ┗┛┗┗┣┛┗┛┗┻┛┗┗┻        //
//           ┛      ┛                 //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract GPSWV is ERC721Creator {
    constructor() ERC721Creator("Gypsy Waves", "GPSWV") {}
}
