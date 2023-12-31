// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opera Curiosa Poster 1979
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//                                                             //
//       _|_|      _|_|_|  _|_|_|    _|_|_|_|_|    _|_|        //
//     _|    _|  _|        _|    _|          _|  _|    _|      //
//     _|    _|  _|        _|_|_|          _|      _|_|_|      //
//     _|    _|  _|        _|            _|            _|      //
//       _|_|      _|_|_|  _|          _|        _|_|_|        //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract OCP79 is ERC721Creator {
    constructor() ERC721Creator("Opera Curiosa Poster 1979", "OCP79") {}
}
