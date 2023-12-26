// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OL1Y ON CHAIN EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//       ____  __   ____  __   ____  ____________    //
//      / __ \/ /  <  \ \/ /  / __ \/ ____/ ____/    //
//     / / / / /   / / \  /  / / / / /   / __/       //
//    / /_/ / /___/ /  / /  / /_/ / /___/ /___       //
//    \____/_____/_/  /_/   \____/\____/_____/       //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract OL1YOCE is ERC1155Creator {
    constructor() ERC1155Creator("OL1Y ON CHAIN EDITIONS", "OL1YOCE") {}
}
