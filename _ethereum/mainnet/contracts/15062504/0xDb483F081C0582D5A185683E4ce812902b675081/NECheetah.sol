
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nito Editions - Cheetah
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
//    NNNNNNNN        NNNNNNNN  iiii          tttt                           PPPPPPPPPPPPPPPPP   hhhhhhh                                       tttt                                    //
//    N:::::::N       N::::::N i::::i      ttt:::t                           P::::::::::::::::P  h:::::h                                    ttt:::t                                    //
//    N::::::::N      N::::::N  iiii       t:::::t                           P::::::PPPPPP:::::P h:::::h                                    t:::::t                                    //
//    N:::::::::N     N::::::N             t:::::t                           PP:::::P     P:::::Ph:::::h                                    t:::::t                                    //
//    N::::::::::N    N::::::Niiiiiiittttttt:::::ttttttt       ooooooooooo     P::::P     P:::::P h::::h hhhhh          ooooooooooo   ttttttt:::::ttttttt       ooooooooooo            //
//    N:::::::::::N   N::::::Ni:::::it:::::::::::::::::t     oo:::::::::::oo   P::::P     P:::::P h::::hh:::::hhh     oo:::::::::::oo t:::::::::::::::::t     oo:::::::::::oo          //
//    N:::::::N::::N  N::::::N i::::it:::::::::::::::::t    o:::::::::::::::o  P::::PPPPPP:::::P  h::::::::::::::hh  o:::::::::::::::ot:::::::::::::::::t    o:::::::::::::::o         //
//    N::::::N N::::N N::::::N i::::itttttt:::::::tttttt    o:::::ooooo:::::o  P:::::::::::::PP   h:::::::hhh::::::h o:::::ooooo:::::otttttt:::::::tttttt    o:::::ooooo:::::o         //
//    N::::::N  N::::N:::::::N i::::i      t:::::t          o::::o     o::::o  P::::PPPPPPPPP     h::::::h   h::::::ho::::o     o::::o      t:::::t          o::::o     o::::o         //
//    N::::::N   N:::::::::::N i::::i      t:::::t          o::::o     o::::o  P::::P             h:::::h     h:::::ho::::o     o::::o      t:::::t          o::::o     o::::o         //
//    N::::::N    N::::::::::N i::::i      t:::::t          o::::o     o::::o  P::::P             h:::::h     h:::::ho::::o     o::::o      t:::::t          o::::o     o::::o         //
//    N::::::N     N:::::::::N i::::i      t:::::t    tttttto::::o     o::::o  P::::P             h:::::h     h:::::ho::::o     o::::o      t:::::t    tttttto::::o     o::::o         //
//    N::::::N      N::::::::Ni::::::i     t::::::tttt:::::to:::::ooooo:::::oPP::::::PP           h:::::h     h:::::ho:::::ooooo:::::o      t::::::tttt:::::to:::::ooooo:::::o         //
//    N::::::N       N:::::::Ni::::::i     tt::::::::::::::to:::::::::::::::oP::::::::P           h:::::h     h:::::ho:::::::::::::::o      tt::::::::::::::to:::::::::::::::o         //
//    N::::::N        N::::::Ni::::::i       tt:::::::::::tt oo:::::::::::oo P::::::::P           h:::::h     h:::::h oo:::::::::::oo         tt:::::::::::tt oo:::::::::::oo          //
//    NNNNNNNN         NNNNNNNiiiiiiii         ttttttttttt     ooooooooooo   PPPPPPPPPP           hhhhhhh     hhhhhhh   ooooooooooo             ttttttttttt     ooooooooooo            //
//                                                                                                                                                                                     //
//                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NECheetah is ERC721Creator {
    constructor() ERC721Creator("Nito Editions - Cheetah", "NECheetah") {}
}
