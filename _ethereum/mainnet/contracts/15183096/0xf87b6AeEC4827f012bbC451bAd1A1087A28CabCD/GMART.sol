
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//            GGGGGGGGGGGGGMMMMMMMM               MMMMMMMM                    AAA               RRRRRRRRRRRRRRRRR   TTTTTTTTTTTTTTTTTTTTTTT    //
//         GGG::::::::::::GM:::::::M             M:::::::M                   A:::A              R::::::::::::::::R  T:::::::::::::::::::::T    //
//       GG:::::::::::::::GM::::::::M           M::::::::M                  A:::::A             R::::::RRRRRR:::::R T:::::::::::::::::::::T    //
//      G:::::GGGGGGGG::::GM:::::::::M         M:::::::::M                 A:::::::A            RR:::::R     R:::::RT:::::TT:::::::TT:::::T    //
//     G:::::G       GGGGGGM::::::::::M       M::::::::::M                A:::::::::A             R::::R     R:::::RTTTTTT  T:::::T  TTTTTT    //
//    G:::::G              M:::::::::::M     M:::::::::::M               A:::::A:::::A            R::::R     R:::::R        T:::::T            //
//    G:::::G              M:::::::M::::M   M::::M:::::::M              A:::::A A:::::A           R::::RRRRRR:::::R         T:::::T            //
//    G:::::G    GGGGGGGGGGM::::::M M::::M M::::M M::::::M             A:::::A   A:::::A          R:::::::::::::RR          T:::::T            //
//    G:::::G    G::::::::GM::::::M  M::::M::::M  M::::::M            A:::::A     A:::::A         R::::RRRRRR:::::R         T:::::T            //
//    G:::::G    GGGGG::::GM::::::M   M:::::::M   M::::::M           A:::::AAAAAAAAA:::::A        R::::R     R:::::R        T:::::T            //
//    G:::::G        G::::GM::::::M    M:::::M    M::::::M          A:::::::::::::::::::::A       R::::R     R:::::R        T:::::T            //
//     G:::::G       G::::GM::::::M     MMMMM     M::::::M         A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R        T:::::T            //
//      G:::::GGGGGGGG::::GM::::::M               M::::::M        A:::::A             A:::::A   RR:::::R     R:::::R      TT:::::::TT          //
//       GG:::::::::::::::GM::::::M               M::::::M       A:::::A               A:::::A  R::::::R     R:::::R      T:::::::::T          //
//         GGG::::::GGG:::GM::::::M               M::::::M      A:::::A                 A:::::A R::::::R     R:::::R      T:::::::::T          //
//            GGGGGG   GGGGMMMMMMMM               MMMMMMMM     AAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR      TTTTTTTTTTT          //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMART is ERC721Creator {
    constructor() ERC721Creator("GM Art Collection", "GMART") {}
}
