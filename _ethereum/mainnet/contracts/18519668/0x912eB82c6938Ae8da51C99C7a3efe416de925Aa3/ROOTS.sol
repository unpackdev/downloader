// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GROOTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//       __________  ____  ____  ___________    //
//      / ____/ __ \/ __ \/ __ \/_  __/ ___/    //
//     / / __/ /_/ / / / / / / / / /  \__ \     //
//    / /_/ / _, _/ /_/ / /_/ / / /  ___/ /     //
//    \____/_/ |_|\____/\____/ /_/  /____/      //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract ROOTS is ERC721Creator {
    constructor() ERC721Creator("GROOTS", "ROOTS") {}
}
