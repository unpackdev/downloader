// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//    .__         __                //
//    |  |  __ __|  | _______       //
//    |  | |  |  \  |/ /\__  \      //
//    |  |_|  |  /    <  / __ \_    //
//    |____/____/|__|_ \(____  /    //
//                    \/     \/     //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract LLL is ERC721Creator {
    constructor() ERC721Creator("test", "LLL") {}
}
