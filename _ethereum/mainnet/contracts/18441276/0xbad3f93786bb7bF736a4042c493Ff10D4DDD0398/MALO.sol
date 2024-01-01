// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GenArt Onchain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                               _|                //
//     _|_|_|  _|_|      _|_|_|  _|    _|_|        //
//     _|    _|    _|  _|    _|  _|  _|    _|      //
//     _|    _|    _|  _|    _|  _|  _|    _|      //
//     _|    _|    _|    _|_|_|  _|    _|_|        //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MALO is ERC721Creator {
    constructor() ERC721Creator("GenArt Onchain", "MALO") {}
}
