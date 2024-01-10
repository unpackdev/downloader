
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Picasso x Matisse - The Dance of Les Demoiselles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     _|_|_|              _|      _|     //
//     _|    _|  _|    _|  _|_|  _|_|     //
//     _|_|_|      _|_|    _|  _|  _|     //
//     _|        _|    _|  _|      _|     //
//     _|        _|    _|  _|      _|     //
//                                        //
//     _|_|_|      _|_|    _|_|_|_|_|     //
//     _|    _|  _|    _|      _|         //
//     _|    _|  _|_|_|_|      _|         //
//     _|    _|  _|    _|      _|         //
//     _|_|_|    _|    _|      _|         //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PxM is ERC721Creator {
    constructor() ERC721Creator("Picasso x Matisse - The Dance of Les Demoiselles", "PxM") {}
}
