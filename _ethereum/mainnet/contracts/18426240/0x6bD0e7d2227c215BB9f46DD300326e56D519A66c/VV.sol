// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Visions From The Void
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//    ____   ____.__       .__                          //
//    \   \ /   /|__| _____|__| ____   ____   ______    //
//     \   Y   / |  |/  ___/  |/  _ \ /    \ /  ___/    //
//      \     /  |  |\___ \|  (  <_> )   |  \\___ \     //
//       \___/   |__/____  >__|\____/|___|  /____  >    //
//                       \/               \/     \/     //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract VV is ERC721Creator {
    constructor() ERC721Creator("Visions From The Void", "VV") {}
}
