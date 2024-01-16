
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sketchbook dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//          /     _/_    /   /        /       /                           //
//     (   /<  _  /  _, /_  /  __ __ /<    __/ _   _  __,  _ _ _   (      //
//    /_)_/ |_(/_(__(__/ /_/_)(_)(_)/ |_  (_/_/ (_(/_(_/(_/ / / /_/_)_    //
//                                                                        //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract SD is ERC721Creator {
    constructor() ERC721Creator("sketchbook dreams", "SD") {}
}
