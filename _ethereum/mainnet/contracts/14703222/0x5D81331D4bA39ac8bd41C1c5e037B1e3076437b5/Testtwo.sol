
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testing two
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    ___________              __       //
//    \__    ___/___   _______/  |_     //
//      |    |_/ __ \ /  ___/\   __\    //
//      |    |\  ___/ \___ \  |  |      //
//      |____| \___  >____  > |__|      //
//                 \/     \/            //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract Testtwo is ERC721Creator {
    constructor() ERC721Creator("Testing two", "Testtwo") {}
}
