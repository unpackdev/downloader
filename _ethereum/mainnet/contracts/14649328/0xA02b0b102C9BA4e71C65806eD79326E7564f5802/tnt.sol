
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pixxelrocket
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//           _              _             _       _       //
//      _ __(_)_ ____ _____| |_ _ ___  __| |_____| |_     //
//     | '_ \ \ \ /\ \ / -_) | '_/ _ \/ _| / / -_)  _|    //
//     | .__/_/_\_\/_\_\___|_|_| \___/\__|_\_\___|\__|    //
//     |_|                                                //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract tnt is ERC721Creator {
    constructor() ERC721Creator("pixxelrocket", "tnt") {}
}
