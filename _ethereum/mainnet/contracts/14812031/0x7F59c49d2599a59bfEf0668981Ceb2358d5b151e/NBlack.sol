
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nataly Blacksmith
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//    NNNNNNNN        NNNNNNNNBBBBBBBBBBBBBBBBB   lllllll                                      kkkkkkkk               //
//    N:::::::N       N::::::NB::::::::::::::::B  l:::::l                                      k::::::k               //
//    N::::::::N      N::::::NB::::::BBBBBB:::::B l:::::l                                      k::::::k               //
//    N:::::::::N     N::::::NBB:::::B     B:::::Bl:::::l                                      k::::::k               //
//    N::::::::::N    N::::::N  B::::B     B:::::B l::::l   aaaaaaaaaaaaa      cccccccccccccccc k:::::k    kkkkkkk    //
//    N:::::::::::N   N::::::N  B::::B     B:::::B l::::l   a::::::::::::a   cc:::::::::::::::c k:::::k   k:::::k     //
//    N:::::::N::::N  N::::::N  B::::BBBBBB:::::B  l::::l   aaaaaaaaa:::::a c:::::::::::::::::c k:::::k  k:::::k      //
//    N::::::N N::::N N::::::N  B:::::::::::::BB   l::::l            a::::ac:::::::cccccc:::::c k:::::k k:::::k       //
//    N::::::N  N::::N:::::::N  B::::BBBBBB:::::B  l::::l     aaaaaaa:::::ac::::::c     ccccccc k::::::k:::::k        //
//    N::::::N   N:::::::::::N  B::::B     B:::::B l::::l   aa::::::::::::ac:::::c              k:::::::::::k         //
//    N::::::N    N::::::::::N  B::::B     B:::::B l::::l  a::::aaaa::::::ac:::::c              k:::::::::::k         //
//    N::::::N     N:::::::::N  B::::B     B:::::B l::::l a::::a    a:::::ac::::::c     ccccccc k::::::k:::::k        //
//    N::::::N      N::::::::NBB:::::BBBBBB::::::Bl::::::la::::a    a:::::ac:::::::cccccc:::::ck::::::k k:::::k       //
//    N::::::N       N:::::::NB:::::::::::::::::B l::::::la:::::aaaa::::::a c:::::::::::::::::ck::::::k  k:::::k      //
//    N::::::N        N::::::NB::::::::::::::::B  l::::::l a::::::::::aa:::a cc:::::::::::::::ck::::::k   k:::::k     //
//    NNNNNNNN         NNNNNNNBBBBBBBBBBBBBBBBB   llllllll  aaaaaaaaaa  aaaa   cccccccccccccccckkkkkkkk    kkkkkkk    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NBlack is ERC721Creator {
    constructor() ERC721Creator("Nataly Blacksmith", "NBlack") {}
}
