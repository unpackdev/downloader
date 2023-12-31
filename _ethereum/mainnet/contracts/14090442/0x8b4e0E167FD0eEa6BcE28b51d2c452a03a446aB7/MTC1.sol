
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manifold Test Contract 1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//          ╓███▀ ╙███▄    ███████████▄╟█████████▌╟███  █████  ████▐██████████▐███▌ ,▓██▀─    //
//        ╓███▀     ╙███▓  ████    ████   ▐███▌    ███▌▐██▀███▐███ ▐███─  ╙███▀███▌███▀       //
//         ╙███▄   ╓███▀   ████    ████   ▐███▌    ╙██████ ╟█████▌ ▐███─      j███▌└▀███      //
//           └▀▀▀ ╙▀▀▀     ▀▀▀▀    ▀▀▀▀    ▀▀▀`     ▀▀▀▀▀   ▀▀▀▀▀  └▀▀▀        ▀▀▀^   ▀▀▀^    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MTC1 is ERC721Creator {
    constructor() ERC721Creator("Manifold Test Contract 1", "MTC1") {}
}
