// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Portraits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//      ____   ___  ____ _____ ____      _    ___ _____ ____      //
//     |  _ \ / _ \|  _ \_   _|  _ \    / \  |_ _|_   _/ ___|     //
//     | |_) | | | | |_) || | | |_) |  / _ \  | |  | | \___ \     //
//     |  __/| |_| |  _ < | | |  _ <  / ___ \ | |  | |  ___) |    //
//     |_|    \___/|_| \_\|_| |_| \_\/_/   \_\___| |_| |____/     //
//                                                                //
//         A Collection of Portraits by Andres Patricio           //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract PORTS is ERC721Creator {
    constructor() ERC721Creator("Portraits", "PORTS") {}
}
