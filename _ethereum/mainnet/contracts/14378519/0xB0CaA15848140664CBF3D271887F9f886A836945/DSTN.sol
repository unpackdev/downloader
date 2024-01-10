
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Destination DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//    DDDDDDDDDDDDD           SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTTNNNNNNNN        NNNNNNNN    //
//    D::::::::::::DDD      SS:::::::::::::::ST:::::::::::::::::::::TN:::::::N       N::::::N    //
//    D:::::::::::::::DD   S:::::SSSSSS::::::ST:::::::::::::::::::::TN::::::::N      N::::::N    //
//    DDD:::::DDDDD:::::D  S:::::S     SSSSSSST:::::TT:::::::TT:::::TN:::::::::N     N::::::N    //
//      D:::::D    D:::::D S:::::S            TTTTTT  T:::::T  TTTTTTN::::::::::N    N::::::N    //
//      D:::::D     D:::::DS:::::S                    T:::::T        N:::::::::::N   N::::::N    //
//      D:::::D     D:::::D S::::SSSS                 T:::::T        N:::::::N::::N  N::::::N    //
//      D:::::D     D:::::D  SS::::::SSSSS            T:::::T        N::::::N N::::N N::::::N    //
//      D:::::D     D:::::D    SSS::::::::SS          T:::::T        N::::::N  N::::N:::::::N    //
//      D:::::D     D:::::D       SSSSSS::::S         T:::::T        N::::::N   N:::::::::::N    //
//      D:::::D     D:::::D            S:::::S        T:::::T        N::::::N    N::::::::::N    //
//      D:::::D    D:::::D             S:::::S        T:::::T        N::::::N     N:::::::::N    //
//    DDD:::::DDDDD:::::D  SSSSSSS     S:::::S      TT:::::::TT      N::::::N      N::::::::N    //
//    D:::::::::::::::DD   S::::::SSSSSS:::::S      T:::::::::T      N::::::N       N:::::::N    //
//    D::::::::::::DDD     S:::::::::::::::SS       T:::::::::T      N::::::N        N::::::N    //
//    DDDDDDDDDDDDD         SSSSSSSSSSSSSSS         TTTTTTTTTTT      NNNNNNNN         NNNNNNN    //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract DSTN is ERC721Creator {
    constructor() ERC721Creator("Destination DAO", "DSTN") {}
}
