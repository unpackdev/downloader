
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ATLAS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//          .o.       ooooooooooooo ooooo              .o.        .oooooo..o     //
//         .888.      8'   888   `8 `888'             .888.      d8P'    `Y8     //
//        .8"888.          888       888             .8"888.     Y88bo.          //
//       .8' `888.         888       888            .8' `888.     `"Y8888o.      //
//      .88ooo8888.        888       888           .88ooo8888.        `"Y88b     //
//     .8'     `888.       888       888       o  .8'     `888.  oo     .d8P     //
//    o88o     o8888o     o888o     o888ooooood8 o88o     o8888o 8""88888P'      //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract ATL is ERC721Creator {
    constructor() ERC721Creator("ATLAS", "ATL") {}
}
