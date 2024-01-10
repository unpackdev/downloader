
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TV Series
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//             \  /            //
//              \/             //
//       .===============.     //
//       | .-----------. |     //
//       | |           | |     //
//       | | TV Series | |     //
//       | |           | |     //
//       | '-----------' |     //
//       |===============|     //
//       |###############|     //
//       '==============='     //
//                             //
//                             //
/////////////////////////////////


contract TVSeries is ERC721Creator {
    constructor() ERC721Creator("TV Series", "TVSeries") {}
}
