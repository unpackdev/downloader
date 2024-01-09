
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matters Team
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      __  __       _   _                    //
//     |  \/  | __ _| |_| |_ ___ _ __ ___     //
//     | |\/| |/ _` | __| __/ _ \ '__/ __|    //
//     | |  | | (_| | |_| ||  __/ |  \__ \    //
//     |_|  |_|\__,_|\__|\__\___|_|  |___/    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MATT is ERC721Creator {
    constructor() ERC721Creator("Matters Team", "MATT") {}
}
