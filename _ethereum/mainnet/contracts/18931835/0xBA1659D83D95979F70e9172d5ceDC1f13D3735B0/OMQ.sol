// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: otaku meme queen
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//         /\  /\           //
//      ヾ(*´∀｀*)ﾉ           //
//     ---------------      //
//    |otaku meme queen|    //
//     ---------------      //
//       (        )))))     //
//        | |  | |          //
//        (_)  (_)          //
//                          //
//                          //
//////////////////////////////


contract OMQ is ERC721Creator {
    constructor() ERC721Creator("otaku meme queen", "OMQ") {}
}
