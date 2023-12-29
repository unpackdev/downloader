// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Azuki Australia x Garden Tour presents MELBOURNE GARDEN
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//       _____   ____ ___  _____________ ___ ____  __.___     //
//      /  _  \ |    |   \/   _____/    |   \    |/ _|   |    //
//     /  /_\  \|    |   /\_____  \|    |   /      < |   |    //
//    /    |    \    |  / /        \    |  /|    |  \|   |    //
//    \____|__  /______/ /_______  /______/ |____|__ \___|    //
//            \/                 \/                 \/        //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract AUSUKI is ERC1155Creator {
    constructor() ERC1155Creator("Azuki Australia x Garden Tour presents MELBOURNE GARDEN", "AUSUKI") {}
}
