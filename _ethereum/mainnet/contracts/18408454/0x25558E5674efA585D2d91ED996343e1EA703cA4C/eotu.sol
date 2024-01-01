// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Echoes of the Unspoken
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//           .__.__                                  //
//      _____|__|  |   ____   ____   ____  ____      //
//     /  ___/  |  | _/ __ \ /    \_/ ___\/ __ \     //
//     \___ \|  |  |_\  ___/|   |  \  \__\  ___/     //
//    /____  >__|____/\___  >___|  /\___  >___  >    //
//         \/             \/     \/     \/    \/     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract eotu is ERC721Creator {
    constructor() ERC721Creator("Echoes of the Unspoken", "eotu") {}
}
