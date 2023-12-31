// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Descent Into Oblivion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//     __      __               .__                             //
//    /  \    /  \____   ____   |__| ______   _____   ____      //
//    \   \/\/   /  _ \_/ __ \  |  |/  ___/  /     \_/ __ \     //
//     \        (  <_> )  ___/  |  |\___ \  |  Y Y  \  ___/     //
//      \__/\  / \____/ \___  > |__/____  > |__|_|  /\___  >    //
//           \/             \/          \/        \/     \/     //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract DIO is ERC721Creator {
    constructor() ERC721Creator("Descent Into Oblivion", "DIO") {}
}
