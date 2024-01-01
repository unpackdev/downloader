// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Goin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//      █████   ██████   ██ ███    ██     //
//     ██   ██ ██  ████ ███ ████   ██     //
//      ██████ ██ ██ ██  ██ ██ ██  ██     //
//          ██ ████  ██  ██ ██  ██ ██     //
//      █████   ██████   ██ ██   ████     //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract GOIN is ERC721Creator {
    constructor() ERC721Creator("Goin", "GOIN") {}
}
