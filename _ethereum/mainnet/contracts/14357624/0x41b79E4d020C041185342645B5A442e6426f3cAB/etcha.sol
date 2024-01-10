
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: etcha
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                 tttt                             hhhhhhh                                   //
//                              ttt:::t                             h:::::h                                   //
//                              t:::::t                             h:::::h                                   //
//                              t:::::t                             h:::::h                                   //
//        eeeeeeeeeeee    ttttttt:::::ttttttt        cccccccccccccccch::::h hhhhh         aaaaaaaaaaaaa       //
//      ee::::::::::::ee  t:::::::::::::::::t      cc:::::::::::::::ch::::hh:::::hhh      a::::::::::::a      //
//     e::::::eeeee:::::eet:::::::::::::::::t     c:::::::::::::::::ch::::::::::::::hh    aaaaaaaaa:::::a     //
//    e::::::e     e:::::etttttt:::::::tttttt    c:::::::cccccc:::::ch:::::::hhh::::::h            a::::a     //
//    e:::::::eeeee::::::e      t:::::t          c::::::c     ccccccch::::::h   h::::::h    aaaaaaa:::::a     //
//    e:::::::::::::::::e       t:::::t          c:::::c             h:::::h     h:::::h  aa::::::::::::a     //
//    e::::::eeeeeeeeeee        t:::::t          c:::::c             h:::::h     h:::::h a::::aaaa::::::a     //
//    e:::::::e                 t:::::t    ttttttc::::::c     ccccccch:::::h     h:::::ha::::a    a:::::a     //
//    e::::::::e                t::::::tttt:::::tc:::::::cccccc:::::ch:::::h     h:::::ha::::a    a:::::a     //
//     e::::::::eeeeeeee        tt::::::::::::::t c:::::::::::::::::ch:::::h     h:::::ha:::::aaaa::::::a     //
//      ee:::::::::::::e          tt:::::::::::tt  cc:::::::::::::::ch:::::h     h:::::h a::::::::::aa:::a    //
//        eeeeeeeeeeeeee            ttttttttttt      cccccccccccccccchhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract etcha is ERC721Creator {
    constructor() ERC721Creator("etcha", "etcha") {}
}
