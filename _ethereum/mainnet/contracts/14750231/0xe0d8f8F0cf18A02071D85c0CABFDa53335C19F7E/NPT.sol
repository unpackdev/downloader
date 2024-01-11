
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEO_PIRATES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//    NNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO                             PPPPPPPPPPPPPPPPP   IIIIIIIIIIRRRRRRRRRRRRRRRRR                  AAA         TTTTTTTTTTTTTTTTTTTTTTTEEEEEEEEEEEEEEEEEEEEEE   SSSSSSSSSSSSSSS     //
//    N:::::::N       N::::::NE::::::::::::::::::::E   OO:::::::::OO                           P::::::::::::::::P  I::::::::IR::::::::::::::::R                A:::A        T:::::::::::::::::::::TE::::::::::::::::::::E SS:::::::::::::::S    //
//    N::::::::N      N::::::NE::::::::::::::::::::E OO:::::::::::::OO                         P::::::PPPPPP:::::P I::::::::IR::::::RRRRRR:::::R              A:::::A       T:::::::::::::::::::::TE::::::::::::::::::::ES:::::SSSSSS::::::S    //
//    N:::::::::N     N::::::NEE::::::EEEEEEEEE::::EO:::::::OOO:::::::O                        PP:::::P     P:::::PII::::::IIRR:::::R     R:::::R            A:::::::A      T:::::TT:::::::TT:::::TEE::::::EEEEEEEEE::::ES:::::S     SSSSSSS    //
//    N::::::::::N    N::::::N  E:::::E       EEEEEEO::::::O   O::::::O                          P::::P     P:::::P  I::::I    R::::R     R:::::R           A:::::::::A     TTTTTT  T:::::T  TTTTTT  E:::::E       EEEEEES:::::S                //
//    N:::::::::::N   N::::::N  E:::::E             O:::::O     O:::::O                          P::::P     P:::::P  I::::I    R::::R     R:::::R          A:::::A:::::A            T:::::T          E:::::E             S:::::S                //
//    N:::::::N::::N  N::::::N  E::::::EEEEEEEEEE   O:::::O     O:::::O                          P::::PPPPPP:::::P   I::::I    R::::RRRRRR:::::R          A:::::A A:::::A           T:::::T          E::::::EEEEEEEEEE    S::::SSSS             //
//    N::::::N N::::N N::::::N  E:::::::::::::::E   O:::::O     O:::::O                          P:::::::::::::PP    I::::I    R:::::::::::::RR          A:::::A   A:::::A          T:::::T          E:::::::::::::::E     SS::::::SSSSS        //
//    N::::::N  N::::N:::::::N  E:::::::::::::::E   O:::::O     O:::::O                          P::::PPPPPPPPP      I::::I    R::::RRRRRR:::::R        A:::::A     A:::::A         T:::::T          E:::::::::::::::E       SSS::::::::SS      //
//    N::::::N   N:::::::::::N  E::::::EEEEEEEEEE   O:::::O     O:::::O                          P::::P              I::::I    R::::R     R:::::R      A:::::AAAAAAAAA:::::A        T:::::T          E::::::EEEEEEEEEE          SSSSSS::::S     //
//    N::::::N    N::::::::::N  E:::::E             O:::::O     O:::::O                          P::::P              I::::I    R::::R     R:::::R     A:::::::::::::::::::::A       T:::::T          E:::::E                         S:::::S    //
//    N::::::N     N:::::::::N  E:::::E       EEEEEEO::::::O   O::::::O                          P::::P              I::::I    R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::A      T:::::T          E:::::E       EEEEEE            S:::::S    //
//    N::::::N      N::::::::NEE::::::EEEEEEEE:::::EO:::::::OOO:::::::O                        PP::::::PP          II::::::IIRR:::::R     R:::::R   A:::::A             A:::::A   TT:::::::TT      EE::::::EEEEEEEE:::::ESSSSSSS     S:::::S    //
//    N::::::N       N:::::::NE::::::::::::::::::::E OO:::::::::::::OO                         P::::::::P          I::::::::IR::::::R     R:::::R  A:::::A               A:::::A  T:::::::::T      E::::::::::::::::::::ES::::::SSSSSS:::::S    //
//    N::::::N        N::::::NE::::::::::::::::::::E   OO:::::::::OO                           P::::::::P          I::::::::IR::::::R     R:::::R A:::::A                 A:::::A T:::::::::T      E::::::::::::::::::::ES:::::::::::::::SS     //
//    NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO                             PPPPPPPPPP          IIIIIIIIIIRRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAATTTTTTTTTTT      EEEEEEEEEEEEEEEEEEEEEE SSSSSSSSSSSSSSS       //
//                                                                     ________________________                                                                                                                                                 //
//                                                                     _::::::::::::::::::::::_                                                                                                                                                 //
//                                                                     ________________________                                                                                                                                                 //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NPT is ERC721Creator {
    constructor() ERC721Creator("NEO_PIRATES", "NPT") {}
}
