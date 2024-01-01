// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthetic Dreams Riabovitchev
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                bbbbbbbb                                                                                                                                                                        //
//                         iiii                   b::::::b                                                      iiii          tttt                             hhhhhhh                                                            //
//                        i::::i                  b::::::b                                                     i::::i      ttt:::t                             h:::::h                                                            //
//                         iiii                   b::::::b                                                      iiii       t:::::t                             h:::::h                                                            //
//                                                 b:::::b                                                                 t:::::t                             h:::::h                                                            //
//    rrrrr   rrrrrrrrr  iiiiiii   aaaaaaaaaaaaa   b:::::bbbbbbbbb       ooooooooooo vvvvvvv           vvvvvvviiiiiiittttttt:::::ttttttt        cccccccccccccccch::::h hhhhh           eeeeeeeeeeee  vvvvvvv           vvvvvvv    //
//    r::::rrr:::::::::r i:::::i   a::::::::::::a  b::::::::::::::bb   oo:::::::::::oov:::::v         v:::::v i:::::it:::::::::::::::::t      cc:::::::::::::::ch::::hh:::::hhh      ee::::::::::::ee v:::::v         v:::::v     //
//    r:::::::::::::::::r i::::i   aaaaaaaaa:::::a b::::::::::::::::b o:::::::::::::::ov:::::v       v:::::v   i::::it:::::::::::::::::t     c:::::::::::::::::ch::::::::::::::hh   e::::::eeeee:::::eev:::::v       v:::::v      //
//    rr::::::rrrrr::::::ri::::i            a::::a b:::::bbbbb:::::::bo:::::ooooo:::::o v:::::v     v:::::v    i::::itttttt:::::::tttttt    c:::::::cccccc:::::ch:::::::hhh::::::h e::::::e     e:::::e v:::::v     v:::::v       //
//     r:::::r     r:::::ri::::i     aaaaaaa:::::a b:::::b    b::::::bo::::o     o::::o  v:::::v   v:::::v     i::::i      t:::::t          c::::::c     ccccccch::::::h   h::::::he:::::::eeeee::::::e  v:::::v   v:::::v        //
//     r:::::r     rrrrrrri::::i   aa::::::::::::a b:::::b     b:::::bo::::o     o::::o   v:::::v v:::::v      i::::i      t:::::t          c:::::c             h:::::h     h:::::he:::::::::::::::::e    v:::::v v:::::v         //
//     r:::::r            i::::i  a::::aaaa::::::a b:::::b     b:::::bo::::o     o::::o    v:::::v:::::v       i::::i      t:::::t          c:::::c             h:::::h     h:::::he::::::eeeeeeeeeee      v:::::v:::::v          //
//     r:::::r            i::::i a::::a    a:::::a b:::::b     b:::::bo::::o     o::::o     v:::::::::v        i::::i      t:::::t    ttttttc::::::c     ccccccch:::::h     h:::::he:::::::e                v:::::::::v           //
//     r:::::r           i::::::ia::::a    a:::::a b:::::bbbbbb::::::bo:::::ooooo:::::o      v:::::::v        i::::::i     t::::::tttt:::::tc:::::::cccccc:::::ch:::::h     h:::::he::::::::e                v:::::::v            //
//     r:::::r           i::::::ia:::::aaaa::::::a b::::::::::::::::b o:::::::::::::::o       v:::::v         i::::::i     tt::::::::::::::t c:::::::::::::::::ch:::::h     h:::::h e::::::::eeeeeeee         v:::::v             //
//     r:::::r           i::::::i a::::::::::aa:::ab:::::::::::::::b   oo:::::::::::oo         v:::v          i::::::i       tt:::::::::::tt  cc:::::::::::::::ch:::::h     h:::::h  ee:::::::::::::e          v:::v              //
//     rrrrrrr           iiiiiiii  aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb      ooooooooooo            vvv           iiiiiiii         ttttttttttt      cccccccccccccccchhhhhhh     hhhhhhh    eeeeeeeeeeeeee           vvv               //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SDR is ERC1155Creator {
    constructor() ERC1155Creator("Synthetic Dreams Riabovitchev", "SDR") {}
}
