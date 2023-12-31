// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Man Who Laughs PD 2024
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    ⠀⠀⠈⢿⢿⣶⣤⡀⠀⠀⠀⢀⣄⡀⠀⠀⣰⠟⢇⣸⣿⠿⣿⣟⡽⣟⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀            //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⢻⣿⣿⣷⣶⣤⣀⡀⠙⠦⠴⣿⣾⣿⣿⣿⣿⡿⢿⣾⡿⠉⣶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⠀⠀⠀⠀⢿⣿⡉⠉⠛⠿⠿⣷⢶⣶⣿⣭⠹⡿⠉⠀⠀⢸⣿⠁⢠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣇⠀⠀⠀⠘⣿⣧⣤⣀⡀⠀⠁⠀⠋⠀⠀⠀⡀⢠⣤⣴⣿⠇⠀⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣦⠀⠀⠀⠘⣿⣤⠀⠉⠓⠂⠀⠀⠠⠟⠛⢛⠉⣴⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⠳⠄⠀⠀⠘⢿⣦⡄⡀⢀⠀⡀⢠⢀⣼⣼⣿⣿⠃⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡆⠀⢱⡄⠀⠈⢻⣿⣷⣬⣤⣿⣿⣿⣿⣿⢿⠅⠀⠀⠀⡞⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⢱⡄⠀⠀⠉⠛⢿⣿⣿⣿⣿⠿⠛⠃⠀⠀⠀⣾⠁⠀⡇⠀⠀⠀           //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TMWL is ERC721Creator {
    constructor() ERC721Creator("The Man Who Laughs PD 2024", "TMWL") {}
}
