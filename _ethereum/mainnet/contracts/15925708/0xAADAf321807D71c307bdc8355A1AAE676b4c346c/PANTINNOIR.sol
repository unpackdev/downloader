
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PANTIN NOIR
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//    PPPPPPPPPPPPPPPPP        AAA               NNNNNNNN        NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTTIIIIIIIIIINNNNNNNN        NNNNNNNN                    NNNNNNNN        NNNNNNNN     OOOOOOOOO     IIIIIIIIIIRRRRRRRRRRRRRRRRR                                //
//    P::::::::::::::::P      A:::A              N:::::::N       N::::::NT:::::::::::::::::::::TI::::::::IN:::::::N       N::::::N                    N:::::::N       N::::::N   OO:::::::::OO   I::::::::IR::::::::::::::::R                               //
//    P::::::PPPPPP:::::P    A:::::A             N::::::::N      N::::::NT:::::::::::::::::::::TI::::::::IN::::::::N      N::::::N                    N::::::::N      N::::::N OO:::::::::::::OO I::::::::IR::::::RRRRRR:::::R                              //
//    PP:::::P     P:::::P  A:::::::A            N:::::::::N     N::::::NT:::::TT:::::::TT:::::TII::::::IIN:::::::::N     N::::::N                    N:::::::::N     N::::::NO:::::::OOO:::::::OII::::::IIRR:::::R     R:::::R                             //
//      P::::P     P:::::P A:::::::::A           N::::::::::N    N::::::NTTTTTT  T:::::T  TTTTTT  I::::I  N::::::::::N    N::::::N                    N::::::::::N    N::::::NO::::::O   O::::::O  I::::I    R::::R     R:::::R                             //
//      P::::P     P:::::PA:::::A:::::A          N:::::::::::N   N::::::N        T:::::T          I::::I  N:::::::::::N   N::::::N                    N:::::::::::N   N::::::NO:::::O     O:::::O  I::::I    R::::R     R:::::R                             //
//      P::::PPPPPP:::::PA:::::A A:::::A         N:::::::N::::N  N::::::N        T:::::T          I::::I  N:::::::N::::N  N::::::N                    N:::::::N::::N  N::::::NO:::::O     O:::::O  I::::I    R::::RRRRRR:::::R                              //
//      P:::::::::::::PPA:::::A   A:::::A        N::::::N N::::N N::::::N        T:::::T          I::::I  N::::::N N::::N N::::::N                    N::::::N N::::N N::::::NO:::::O     O:::::O  I::::I    R:::::::::::::RR                               //
//      P::::PPPPPPPPP A:::::A     A:::::A       N::::::N  N::::N:::::::N        T:::::T          I::::I  N::::::N  N::::N:::::::N                    N::::::N  N::::N:::::::NO:::::O     O:::::O  I::::I    R::::RRRRRR:::::R                              //
//      P::::P        A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N        T:::::T          I::::I  N::::::N   N:::::::::::N                    N::::::N   N:::::::::::NO:::::O     O:::::O  I::::I    R::::R     R:::::R                             //
//      P::::P       A:::::::::::::::::::::A     N::::::N    N::::::::::N        T:::::T          I::::I  N::::::N    N::::::::::N                    N::::::N    N::::::::::NO:::::O     O:::::O  I::::I    R::::R     R:::::R                             //
//      P::::P      A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N        T:::::T          I::::I  N::::::N     N:::::::::N                    N::::::N     N:::::::::NO::::::O   O::::::O  I::::I    R::::R     R:::::R                             //
//    PP::::::PP   A:::::A             A:::::A   N::::::N      N::::::::N      TT:::::::TT      II::::::IIN::::::N      N::::::::N                    N::::::N      N::::::::NO:::::::OOO:::::::OII::::::IIRR:::::R     R:::::R                             //
//    P::::::::P  A:::::A               A:::::A  N::::::N       N:::::::N      T:::::::::T      I::::::::IN::::::N       N:::::::N                    N::::::N       N:::::::N OO:::::::::::::OO I::::::::IR::::::R     R:::::R                             //
//    P::::::::P A:::::A                 A:::::A N::::::N        N::::::N      T:::::::::T      I::::::::IN::::::N        N::::::N                    N::::::N        N::::::N   OO:::::::::OO   I::::::::IR::::::R     R:::::R                             //
//    PPPPPPPPPPAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN      TTTTTTTTTTT      IIIIIIIIIINNNNNNNN         NNNNNNN                    NNNNNNNN         NNNNNNN     OOOOOOOOO     IIIIIIIIIIRRRRRRRR     RRRRRRR                             //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PANTINNOIR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
