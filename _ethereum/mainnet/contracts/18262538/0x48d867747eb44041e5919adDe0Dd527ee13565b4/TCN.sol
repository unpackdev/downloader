// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test_Contract_Name
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//    ____________________   _______       //
//    \__    ___/\_   ___ \  \      \      //
//      |    |   /    \  \/  /   |   \     //
//      |    |   \     \____/    |    \    //
//      |____|    \______  /\____|__  /    //
//                       \/         \/     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TCN is ERC721Creator {
    constructor() ERC721Creator("Test_Contract_Name", "TCN") {}
}
