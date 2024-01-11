
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This is a test (1)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do      //
//    eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut       //
//    enim ad minim veniam, quis nostrud exercitation ullamco laboris      //
//    nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor       //
//    in reprehenderit in voluptate velit esse cillum dolore eu fugiat     //
//    nulla pariatur. Excepteur sint occaecat cupidatat non proident,      //
//    sunt in culpa qui officia deserunt mollit anim id est laborum        //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract Test1 is ERC721Creator {
    constructor() ERC721Creator("This is a test (1)", "Test1") {}
}
