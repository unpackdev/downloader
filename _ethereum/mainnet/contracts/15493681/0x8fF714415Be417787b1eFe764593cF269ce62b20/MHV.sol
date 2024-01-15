
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mile High Visuals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
//    MMMMMMMM               MMMMMMMM  iiii  lllllll                          HHHHHHHHH     HHHHHHHHH  iiii                     hhhhhhh                  VVVVVVVV           VVVVVVVV iiii                                                       lllllll                      //
//    M:::::::M             M:::::::M i::::i l:::::l                          H:::::::H     H:::::::H i::::i                    h:::::h                  V::::::V           V::::::Vi::::i                                                      l:::::l                      //
//    M::::::::M           M::::::::M  iiii  l:::::l                          H:::::::H     H:::::::H  iiii                     h:::::h                  V::::::V           V::::::V iiii                                                       l:::::l                      //
//    M:::::::::M         M:::::::::M        l:::::l                          HH::::::H     H::::::HH                           h:::::h                  V::::::V           V::::::V                                                            l:::::l                      //
//    M::::::::::M       M::::::::::Miiiiiii  l::::l     eeeeeeeeeeee           H:::::H     H:::::H  iiiiiii    ggggggggg   gggggh::::h hhhhh             V:::::V           V:::::Viiiiiii     ssssssssss   uuuuuu    uuuuuu    aaaaaaaaaaaaa    l::::l     ssssssssss       //
//    M:::::::::::M     M:::::::::::Mi:::::i  l::::l   ee::::::::::::ee         H:::::H     H:::::H  i:::::i   g:::::::::ggg::::gh::::hh:::::hhh           V:::::V         V:::::V i:::::i   ss::::::::::s  u::::u    u::::u    a::::::::::::a   l::::l   ss::::::::::s      //
//    M:::::::M::::M   M::::M:::::::M i::::i  l::::l  e::::::eeeee:::::ee       H::::::HHHHH::::::H   i::::i  g:::::::::::::::::gh::::::::::::::hh          V:::::V       V:::::V   i::::i ss:::::::::::::s u::::u    u::::u    aaaaaaaaa:::::a  l::::l ss:::::::::::::s     //
//    M::::::M M::::M M::::M M::::::M i::::i  l::::l e::::::e     e:::::e       H:::::::::::::::::H   i::::i g::::::ggggg::::::ggh:::::::hhh::::::h          V:::::V     V:::::V    i::::i s::::::ssss:::::su::::u    u::::u             a::::a  l::::l s::::::ssss:::::s    //
//    M::::::M  M::::M::::M  M::::::M i::::i  l::::l e:::::::eeeee::::::e       H:::::::::::::::::H   i::::i g:::::g     g:::::g h::::::h   h::::::h          V:::::V   V:::::V     i::::i  s:::::s  ssssss u::::u    u::::u      aaaaaaa:::::a  l::::l  s:::::s  ssssss     //
//    M::::::M   M:::::::M   M::::::M i::::i  l::::l e:::::::::::::::::e        H::::::HHHHH::::::H   i::::i g:::::g     g:::::g h:::::h     h:::::h           V:::::V V:::::V      i::::i    s::::::s      u::::u    u::::u    aa::::::::::::a  l::::l    s::::::s          //
//    M::::::M    M:::::M    M::::::M i::::i  l::::l e::::::eeeeeeeeeee         H:::::H     H:::::H   i::::i g:::::g     g:::::g h:::::h     h:::::h            V:::::V:::::V       i::::i       s::::::s   u::::u    u::::u   a::::aaaa::::::a  l::::l       s::::::s       //
//    M::::::M     MMMMM     M::::::M i::::i  l::::l e:::::::e                  H:::::H     H:::::H   i::::i g::::::g    g:::::g h:::::h     h:::::h             V:::::::::V        i::::i ssssss   s:::::s u:::::uuuu:::::u  a::::a    a:::::a  l::::l ssssss   s:::::s     //
//    M::::::M               M::::::Mi::::::il::::::le::::::::e               HH::::::H     H::::::HHi::::::ig:::::::ggggg:::::g h:::::h     h:::::h              V:::::::V        i::::::is:::::ssss::::::su:::::::::::::::uua::::a    a:::::a l::::::ls:::::ssss::::::s    //
//    M::::::M               M::::::Mi::::::il::::::l e::::::::eeeeeeee       H:::::::H     H:::::::Hi::::::i g::::::::::::::::g h:::::h     h:::::h               V:::::V         i::::::is::::::::::::::s  u:::::::::::::::ua:::::aaaa::::::a l::::::ls::::::::::::::s     //
//    M::::::M               M::::::Mi::::::il::::::l  ee:::::::::::::e       H:::::::H     H:::::::Hi::::::i  gg::::::::::::::g h:::::h     h:::::h                V:::V          i::::::i s:::::::::::ss    uu::::::::uu:::u a::::::::::aa:::al::::::l s:::::::::::ss      //
//    MMMMMMMM               MMMMMMMMiiiiiiiillllllll    eeeeeeeeeeeeee       HHHHHHHHH     HHHHHHHHHiiiiiiii    gggggggg::::::g hhhhhhh     hhhhhhh                 VVV           iiiiiiii  sssssssssss        uuuuuuuu  uuuu  aaaaaaaaaa  aaaallllllll  sssssssssss        //
//                                                                                                                       g:::::g                                                                                                                                             //
//                                                                                                           gggggg      g:::::g                                                                                                                                             //
//                                                                                                           g:::::gg   gg:::::g                                                                                                                                             //
//                                                                                                            g::::::ggg:::::::g                                                                                                                                             //
//                                                                                                             gg:::::::::::::g                                                                                                                                              //
//                                                                                                               ggg::::::ggg                                                                                                                                                //
//                                                                                                                  gggggg                                                                                                                                                   //
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MHV is ERC721Creator {
    constructor() ERC721Creator("Mile High Visuals", "MHV") {}
}
