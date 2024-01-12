
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Around the world  with GingerBeard
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//            .---.             //
//            |[X]|             //
//     _.==._.""""".___n__      //
//    d __ ___.-''-. _____b     //
//    |[__]  /."""".\ _   |     //
//    |     // /""\ \\_)  |     //
//    |     \\ \__/ //    |     //
//    |Ginger\`.__.'/Beard|     //
//    \=======`-..-'======/     //
//     `-----------------'      //
//                              //
//                              //
//                              //
//////////////////////////////////


contract ATWGB is ERC721Creator {
    constructor() ERC721Creator("Around the world  with GingerBeard", "ATWGB") {}
}
