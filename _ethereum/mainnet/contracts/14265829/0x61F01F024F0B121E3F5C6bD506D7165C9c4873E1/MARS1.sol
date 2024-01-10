
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARS-1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//    MMMMMMMM               MMMMMMMM               AAA               RRRRRRRRRRRRRRRRR      SSSSSSSSSSSSSSS                    1111111       //
//    M:::::::M             M:::::::M              A:::A              R::::::::::::::::R   SS:::::::::::::::S                  1::::::1       //
//    M::::::::M           M::::::::M             A:::::A             R::::::RRRRRR:::::R S:::::SSSSSS::::::S                 1:::::::1       //
//    M:::::::::M         M:::::::::M            A:::::::A            RR:::::R     R:::::RS:::::S     SSSSSSS                 111:::::1       //
//    M::::::::::M       M::::::::::M           A:::::::::A             R::::R     R:::::RS:::::S                                1::::1       //
//    M:::::::::::M     M:::::::::::M          A:::::A:::::A            R::::R     R:::::RS:::::S                                1::::1       //
//    M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A           R::::RRRRRR:::::R  S::::SSSS                             1::::1       //
//    M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A          R:::::::::::::RR    SS::::::SSSSS     ---------------    1::::l       //
//    M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A         R::::RRRRRR:::::R     SSS::::::::SS   -:::::::::::::-    1::::l       //
//    M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A        R::::R     R:::::R       SSSSSS::::S  ---------------    1::::l       //
//    M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::A       R::::R     R:::::R            S:::::S                    1::::l       //
//    M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R            S:::::S                    1::::l       //
//    M::::::M               M::::::M   A:::::A             A:::::A   RR:::::R     R:::::RSSSSSSS     S:::::S                 111::::::111    //
//    M::::::M               M::::::M  A:::::A               A:::::A  R::::::R     R:::::RS::::::SSSSSS:::::S                 1::::::::::1    //
//    M::::::M               M::::::M A:::::A                 A:::::A R::::::R     R:::::RS:::::::::::::::SS                  1::::::::::1    //
//    MMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR SSSSSSSSSSSSSSS                    111111111111    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MARS1 is ERC721Creator {
    constructor() ERC721Creator("MARS-1", "MARS1") {}
}
