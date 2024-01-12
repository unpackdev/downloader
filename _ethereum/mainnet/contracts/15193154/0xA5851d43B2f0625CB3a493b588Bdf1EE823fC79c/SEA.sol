
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Michael Christopher Brown / SuperRare
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//       _____ _________    ____  ________  ____________     //
//      / ___// ____/   |  / __ \/ ____/ / / / ____/ __ \    //
//      \__ \/ __/ / /| | / /_/ / /   / /_/ / __/ / /_/ /    //
//     ___/ / /___/ ___ |/ _, _/ /___/ __  / /___/ _, _/     //
//    /____/_____/_/  |_/_/ |_|\____/_/ /_/_____/_/ |_|      //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract SEA is ERC721Creator {
    constructor() ERC721Creator("Michael Christopher Brown / SuperRare", "SEA") {}
}
