// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coop's Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//      ___      //
//     / __|     //
//    | (__      //
//     \___|     //
//      ___      //
//     / _ \     //
//    | | | |    //
//     \___/     //
//      ___      //
//     / _ \     //
//    | | | |    //
//     \___/     //
//      ___      //
//     | _ \     //
//     |  _/     //
//     |_|       //
//               //
//               //
//               //
///////////////////


contract COOP is ERC721Creator {
    constructor() ERC721Creator("Coop's Contract", "COOP") {}
}
