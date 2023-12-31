// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WORTHLESS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//     __      _____  ___ _____ _  _ _    ___ ___ ___     //
//     \ \    / / _ \| _ \_   _| || | |  | __/ __/ __|    //
//      \ \/\/ / (_) |   / | | | __ | |__| _|\__ \__ \    //
//       \_/\_/ \___/|_|_\ |_| |_||_|____|___|___/___/    //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract WORTH is ERC721Creator {
    constructor() ERC721Creator("WORTHLESS", "WORTH") {}
}
