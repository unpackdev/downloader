// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OLIO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//           .__  .__            //
//      ____ |  | |__| ____      //
//     /  _ \|  | |  |/  _ \     //
//    (  <_> )  |_|  (  <_> )    //
//     \____/|____/__|\____/     //
//                               //
//                               //
//                               //
///////////////////////////////////


contract OLIO is ERC721Creator {
    constructor() ERC721Creator("OLIO", "OLIO") {}
}
