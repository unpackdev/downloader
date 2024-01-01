// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: colors
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                 .__                           //
//      ____  ____ |  |   ___________  ______    //
//    _/ ___\/  _ \|  |  /  _ \_  __ \/  ___/    //
//    \  \__(  <_> )  |_(  <_> )  | \/\___ \     //
//     \___  >____/|____/\____/|__|  /____  >    //
//         \/                             \/     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract CLS is ERC1155Creator {
    constructor() ERC1155Creator("colors", "CLS") {}
}
