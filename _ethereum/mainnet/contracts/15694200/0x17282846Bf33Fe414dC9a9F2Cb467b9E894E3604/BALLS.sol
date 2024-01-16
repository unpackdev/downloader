
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testicles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ___.          .__  .__              //
//    \_ |__ _____  |  | |  |   ______    //
//     | __ \\__  \ |  | |  |  /  ___/    //
//     | \_\ \/ __ \|  |_|  |__\___ \     //
//     |___  (____  /____/____/____  >    //
//         \/     \/               \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract BALLS is ERC721Creator {
    constructor() ERC721Creator("testicles", "BALLS") {}
}
