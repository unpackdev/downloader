// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GROOTS Bidder Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//        ____  ____  ____  ____  ___________    //
//       / __ )/ __ \/ __ \/ __ \/_  __/ ___/    //
//      / __  / /_/ / / / / / / / / /  \__ \     //
//     / /_/ / _, _/ /_/ / /_/ / / /  ___/ /     //
//    /_____/_/ |_|\____/\____/ /_/  /____/      //
//                                               //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract BROOTS is ERC1155Creator {
    constructor() ERC1155Creator("GROOTS Bidder Editions", "BROOTS") {}
}
