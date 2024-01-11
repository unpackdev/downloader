
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CNNNR Mixed Media
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//            _____                   /|    //
//            |   \      ____        / |    //
//      __    |    \    /\   |      /  ;    //
//     /\  \  |     \  /  \  |     /  ;     //
//    /,'\  \ |      \/  : \ |    /   ;     //
//    ~  ;   \|      /   :  \|   /   ;      //
//       |    \     /   :'  |   /    ;      //
//       |     \   /    :   |  /    ;       //
//       |      \ /    :'   | /     ;       //
//       |       /     :    |/     ;        //
//       |      /     :'    |      ;        //
//        \    /      :     |     ;         //
//         \  /      :'     |     ;         //
//          \       :'      |    ;          //
//           \______:_______|___;           //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CMM is ERC721Creator {
    constructor() ERC721Creator("CNNNR Mixed Media", "CMM") {}
}
