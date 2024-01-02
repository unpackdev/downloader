// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VERDANDI GEMINAI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//      __ __    _____    _____    _____     ___     __  __    _____    __          //
//      \\ //    ||==     ||_//    ||  )    ||=||    ||\\||    ||  )    ||          //
//       \V/     ||___    || \\    ||_//    || ||    || \||    ||_//    ||          //
//                                                                                  //
//       _|_|_|  _|_|_|_|  _|      _|  _|_|_|  _|      _|    _|_|    _|_|_|         //
//     _|        _|        _|_|  _|_|    _|    _|_|    _|  _|    _|    _|           //
//     _|  _|_|  _|_|_|    _|  _|  _|    _|    _|  _|  _|  _|_|_|_|    _|           //
//     _|    _|  _|        _|      _|    _|    _|    _|_|  _|    _|    _|           //
//       _|_|_|  _|_|_|_|  _|      _|  _|_|_|  _|      _|  _|    _|  _|_|_|         //
//                                                                                  //
//     "In the brushstrokes of my AI twin, I find echoes of my own imagination,     //
//     a simple harmonious blend of human intuition and digital expression,         //
//     crafting a new language within the tapestry of art." - Verdandi              //
//                                                                                  //
//      © MMXXIII | All rights reserved.                                            //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract GMAI is ERC721Creator {
    constructor() ERC721Creator("VERDANDI GEMINAI", "GMAI") {}
}
