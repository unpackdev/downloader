
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For the love of CC0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                          //
//    FFFFFFFFFFFFFFFFFFFFFF                                                tttt         hhhhhhh                                      lllllll                                                                                   ffffffffffffffff               CCCCCCCCCCCCC       CCCCCCCCCCCCC     000000000              //
//    F::::::::::::::::::::F                                             ttt:::t         h:::::h                                      l:::::l                                                                                  f::::::::::::::::f           CCC::::::::::::C    CCC::::::::::::C   00:::::::::00            //
//    F::::::::::::::::::::F                                             t:::::t         h:::::h                                      l:::::l                                                                                 f::::::::::::::::::f        CC:::::::::::::::C  CC:::::::::::::::C 00:::::::::::::00          //
//    FF::::::FFFFFFFFF::::F                                             t:::::t         h:::::h                                      l:::::l                                                                                 f::::::fffffff:::::f       C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C0:::::::000:::::::0         //
//      F:::::F       FFFFFFooooooooooo   rrrrr   rrrrrrrrr        ttttttt:::::ttttttt    h::::h hhhhh           eeeeeeeeeeee          l::::l    ooooooooooo vvvvvvv           vvvvvvv eeeeeeeeeeee            ooooooooooo    f:::::f       ffffff      C:::::C       CCCCCCC:::::C       CCCCCC0::::::0   0::::::0         //
//      F:::::F           oo:::::::::::oo r::::rrr:::::::::r       t:::::::::::::::::t    h::::hh:::::hhh      ee::::::::::::ee        l::::l  oo:::::::::::oov:::::v         v:::::vee::::::::::::ee        oo:::::::::::oo  f:::::f                  C:::::C             C:::::C              0:::::0     0:::::0         //
//      F::::::FFFFFFFFFFo:::::::::::::::or:::::::::::::::::r      t:::::::::::::::::t    h::::::::::::::hh   e::::::eeeee:::::ee      l::::l o:::::::::::::::ov:::::v       v:::::ve::::::eeeee:::::ee     o:::::::::::::::of:::::::ffffff            C:::::C             C:::::C              0:::::0     0:::::0         //
//      F:::::::::::::::Fo:::::ooooo:::::orr::::::rrrrr::::::r     tttttt:::::::tttttt    h:::::::hhh::::::h e::::::e     e:::::e      l::::l o:::::ooooo:::::o v:::::v     v:::::ve::::::e     e:::::e     o:::::ooooo:::::of::::::::::::f            C:::::C             C:::::C              0:::::0 000 0:::::0         //
//      F:::::::::::::::Fo::::o     o::::o r:::::r     r:::::r           t:::::t          h::::::h   h::::::he:::::::eeeee::::::e      l::::l o::::o     o::::o  v:::::v   v:::::v e:::::::eeeee::::::e     o::::o     o::::of::::::::::::f            C:::::C             C:::::C              0:::::0 000 0:::::0         //
//      F::::::FFFFFFFFFFo::::o     o::::o r:::::r     rrrrrrr           t:::::t          h:::::h     h:::::he:::::::::::::::::e       l::::l o::::o     o::::o   v:::::v v:::::v  e:::::::::::::::::e      o::::o     o::::of:::::::ffffff            C:::::C             C:::::C              0:::::0     0:::::0         //
//      F:::::F          o::::o     o::::o r:::::r                       t:::::t          h:::::h     h:::::he::::::eeeeeeeeeee        l::::l o::::o     o::::o    v:::::v:::::v   e::::::eeeeeeeeeee       o::::o     o::::o f:::::f                  C:::::C             C:::::C              0:::::0     0:::::0         //
//      F:::::F          o::::o     o::::o r:::::r                       t:::::t    tttttth:::::h     h:::::he:::::::e                 l::::l o::::o     o::::o     v:::::::::v    e:::::::e                o::::o     o::::o f:::::f                   C:::::C       CCCCCCC:::::C       CCCCCC0::::::0   0::::::0         //
//    FF:::::::FF        o:::::ooooo:::::o r:::::r                       t::::::tttt:::::th:::::h     h:::::he::::::::e               l::::::lo:::::ooooo:::::o      v:::::::v     e::::::::e               o:::::ooooo:::::of:::::::f                   C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C0:::::::000:::::::0         //
//    F::::::::FF        o:::::::::::::::o r:::::r                       tt::::::::::::::th:::::h     h:::::h e::::::::eeeeeeee       l::::::lo:::::::::::::::o       v:::::v       e::::::::eeeeeeee       o:::::::::::::::of:::::::f                    CC:::::::::::::::C  CC:::::::::::::::C 00:::::::::::::00          //
//    F::::::::FF         oo:::::::::::oo  r:::::r                         tt:::::::::::tth:::::h     h:::::h  ee:::::::::::::e       l::::::l oo:::::::::::oo         v:::v         ee:::::::::::::e        oo:::::::::::oo f:::::::f                      CCC::::::::::::C    CCC::::::::::::C   00:::::::::00            //
//    FFFFFFFFFFF           ooooooooooo    rrrrrrr                           ttttttttttt  hhhhhhh     hhhhhhh    eeeeeeeeeeeeee       llllllll   ooooooooooo            vvv            eeeeeeeeeeeeee          ooooooooooo   fffffffff                         CCCCCCCCCCCCC       CCCCCCCCCCCCC     000000000              //
//                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTLOCC0 is ERC721Creator {
    constructor() ERC721Creator("For the love of CC0", "FTLOCC0") {}
}
