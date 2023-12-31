// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Covenchaser
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//            CCCCCCCCCCCCC                                                                                              hhhhhhh                                                                                           //
//         CCC::::::::::::C                                                                                              h:::::h                                                                                           //
//       CC:::::::::::::::C                                                                                              h:::::h                                                                                           //
//      C:::::CCCCCCCC::::C                                                                                              h:::::h                                                                                           //
//     C:::::C       CCCCCC   ooooooooooo vvvvvvv           vvvvvvv eeeeeeeeeeee    nnnn  nnnnnnnn        cccccccccccccccch::::h hhhhh         aaaaaaaaaaaaa      ssssssssss       eeeeeeeeeeee    rrrrr   rrrrrrrrr       //
//    C:::::C               oo:::::::::::oov:::::v         v:::::vee::::::::::::ee  n:::nn::::::::nn    cc:::::::::::::::ch::::hh:::::hhh      a::::::::::::a   ss::::::::::s    ee::::::::::::ee  r::::rrr:::::::::r      //
//    C:::::C              o:::::::::::::::ov:::::v       v:::::ve::::::eeeee:::::een::::::::::::::nn  c:::::::::::::::::ch::::::::::::::hh    aaaaaaaaa:::::ass:::::::::::::s  e::::::eeeee:::::eer:::::::::::::::::r     //
//    C:::::C              o:::::ooooo:::::o v:::::v     v:::::ve::::::e     e:::::enn:::::::::::::::nc:::::::cccccc:::::ch:::::::hhh::::::h            a::::as::::::ssss:::::se::::::e     e:::::err::::::rrrrr::::::r    //
//    C:::::C              o::::o     o::::o  v:::::v   v:::::v e:::::::eeeee::::::e  n:::::nnnn:::::nc::::::c     ccccccch::::::h   h::::::h    aaaaaaa:::::a s:::::s  ssssss e:::::::eeeee::::::e r:::::r     r:::::r    //
//    C:::::C              o::::o     o::::o   v:::::v v:::::v  e:::::::::::::::::e   n::::n    n::::nc:::::c             h:::::h     h:::::h  aa::::::::::::a   s::::::s      e:::::::::::::::::e  r:::::r     rrrrrrr    //
//    C:::::C              o::::o     o::::o    v:::::v:::::v   e::::::eeeeeeeeeee    n::::n    n::::nc:::::c             h:::::h     h:::::h a::::aaaa::::::a      s::::::s   e::::::eeeeeeeeeee   r:::::r                //
//     C:::::C       CCCCCCo::::o     o::::o     v:::::::::v    e:::::::e             n::::n    n::::nc::::::c     ccccccch:::::h     h:::::ha::::a    a:::::assssss   s:::::s e:::::::e            r:::::r                //
//      C:::::CCCCCCCC::::Co:::::ooooo:::::o      v:::::::v     e::::::::e            n::::n    n::::nc:::::::cccccc:::::ch:::::h     h:::::ha::::a    a:::::as:::::ssss::::::se::::::::e           r:::::r                //
//       CC:::::::::::::::Co:::::::::::::::o       v:::::v       e::::::::eeeeeeee    n::::n    n::::n c:::::::::::::::::ch:::::h     h:::::ha:::::aaaa::::::as::::::::::::::s  e::::::::eeeeeeee   r:::::r                //
//         CCC::::::::::::C oo:::::::::::oo         v:::v         ee:::::::::::::e    n::::n    n::::n  cc:::::::::::::::ch:::::h     h:::::h a::::::::::aa:::as:::::::::::ss    ee:::::::::::::e   r:::::r                //
//            CCCCCCCCCCCCC   ooooooooooo            vvv            eeeeeeeeeeeeee    nnnnnn    nnnnnn    cccccccccccccccchhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa sssssssssss        eeeeeeeeeeeeee   rrrrrrr                //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
//    by Barret Frymire                                                                                                                                                                                                    //
//                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract coven is ERC721Creator {
    constructor() ERC721Creator("Covenchaser", "coven") {}
}
