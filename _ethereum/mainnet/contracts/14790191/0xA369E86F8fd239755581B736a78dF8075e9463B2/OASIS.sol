
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Oasis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//           /.                //
//          /_\_\. o           //
//         |_____L_/)          //
//          |   |  /Y          //
//        ~~~~~~~~~~~          //
//                             //
//    https://theoasis.xyz     //
//                             //
//                             //
/////////////////////////////////


contract OASIS is ERC721Creator {
    constructor() ERC721Creator("The Oasis", "OASIS") {}
}
