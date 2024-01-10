
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Made is to see the world how it is versus how the world should be
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//     ____  ____  _  _      _____ ____    _____ ____  _      ____  _     _        //
//    /  __\/  _ \/ \/ \  /|/  __//  __\  /  __//  _ \/ \  /|/  _ \/ \ /|/ \       //
//    |  \/|| / \|| || |\ |||  \  |  \/|  | |  _| / \|| |\ ||| / \|| |_||| |       //
//    |    /| |-||| || | \|||  /_ |    /  | |_//| |-||| | \||| |-||| | ||| |_/\    //
//    \_/\_\\_/ \|\_/\_/  \|\____\\_/\_\  \____\\_/ \|\_/  \|\_/ \|\_/ \|\____/    //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract UKRN is ERC721Creator {
    constructor() ERC721Creator("Made is to see the world how it is versus how the world should be", "UKRN") {}
}
