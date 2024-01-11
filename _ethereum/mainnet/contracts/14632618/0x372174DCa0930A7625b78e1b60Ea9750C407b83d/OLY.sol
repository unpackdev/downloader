
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Olympiad
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//       __                __  _  _       //
//      / /  _   _ __  __ / _\(_)| |_     //
//     / /  | | | |\ \/ / \ \ | || __|    //
//    / /___| |_| | >  <  _\ \| || |_     //
//    \____/ \__,_|/_/\_\ \__/|_| \__|    //
//                                        //
//                                        //
////////////////////////////////////////////


contract OLY is ERC721Creator {
    constructor() ERC721Creator("The Olympiad", "OLY") {}
}
