
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artists
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     ____  ____  ____    __    ____     //
//    ( ___)(_  _)(  _ \  /__\  (_   )    //
//     )__)  _)(_  )   / /(__)\  / /_     //
//    (__)  (____)(_)\_)(__)(__)(____)    //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract ARTS is ERC721Creator {
    constructor() ERC721Creator("Artists", "ARTS") {}
}
