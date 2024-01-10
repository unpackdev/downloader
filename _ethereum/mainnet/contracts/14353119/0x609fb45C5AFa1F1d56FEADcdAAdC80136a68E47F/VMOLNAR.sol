
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vera MOLNAR  - 2% of disorder in co-operation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    __      __              __  __  ____  _      _   _          _____       //
//     \ \    / /             |  \/  |/ __ \| |    | \ | |   /\   |  __ \     //
//      \ \  / /__ _ __ __ _  | \  / | |  | | |    |  \| |  /  \  | |__) |    //
//       \ \/ / _ \ '__/ _` | | |\/| | |  | | |    | . ` | / /\ \ |  _  /     //
//        \  /  __/ | | (_| | | |  | | |__| | |____| |\  |/ ____ \| | \ \     //
//         \/ \___|_|  \__,_| |_|  |_|\____/|______|_| \_/_/    \_\_|  \_\    //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract VMOLNAR is ERC721Creator {
    constructor() ERC721Creator("Vera MOLNAR  - 2% of disorder in co-operation", "VMOLNAR") {}
}
