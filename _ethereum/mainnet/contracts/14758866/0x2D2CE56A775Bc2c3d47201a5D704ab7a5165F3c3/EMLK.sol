
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Somewhere, Somehow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//     ____ __  __ ____ __   _  _   __       //
//    ( ___|  \/  |_  _|  ) ( )/ ) /__\      //
//     )__) )    ( _)(_ )(__ )  ( /(__)\     //
//    (____|_/\/\_|____|____|_)\_|__)(__)    //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract EMLK is ERC721Creator {
    constructor() ERC721Creator("Somewhere, Somehow", "EMLK") {}
}
