
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lollipop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//                                                                           bbbbbbbb                                                                                           //
//                   hhhhhhh                                     tttt        b::::::b                                                                   hhhhhhh                 //
//                   h:::::h                                  ttt:::t        b::::::b                                                                   h:::::h                 //
//                   h:::::h                                  t:::::t        b::::::b                                                                   h:::::h                 //
//                   h:::::h                                  t:::::t         b:::::b                                                                   h:::::h                 //
//        ssssssssss  h::::h hhhhh         ooooooooooo  ttttttt:::::ttttttt   b:::::bbbbbbbbbyyyyyyy           yyyyyynnnn  nnnnnnnn      ggggggggg   ggggh::::h hhhhh           //
//      ss::::::::::s h::::hh:::::hhh    oo:::::::::::oot:::::::::::::::::t   b::::::::::::::by:::::y         y:::::yn:::nn::::::::nn   g:::::::::ggg::::h::::hh:::::hhh        //
//    ss:::::::::::::sh::::::::::::::hh o:::::::::::::::t:::::::::::::::::t   b::::::::::::::::y:::::y       y:::::y n::::::::::::::nn g:::::::::::::::::h::::::::::::::hh      //
//    s::::::ssss:::::h:::::::hhh::::::ho:::::ooooo:::::tttttt:::::::tttttt   b:::::bbbbb:::::::y:::::y     y:::::y  nn:::::::::::::::g::::::ggggg::::::gh:::::::hhh::::::h     //
//     s:::::s  ssssssh::::::h   h::::::o::::o     o::::o     t:::::t         b:::::b    b::::::by:::::y   y:::::y     n:::::nnnn:::::g:::::g     g:::::gh::::::h   h::::::h    //
//       s::::::s     h:::::h     h:::::o::::o     o::::o     t:::::t         b:::::b     b:::::b y:::::y y:::::y      n::::n    n::::g:::::g     g:::::gh:::::h     h:::::h    //
//          s::::::s  h:::::h     h:::::o::::o     o::::o     t:::::t         b:::::b     b:::::b  y:::::y:::::y       n::::n    n::::g:::::g     g:::::gh:::::h     h:::::h    //
//    ssssss   s:::::sh:::::h     h:::::o::::o     o::::o     t:::::t    tttttb:::::b     b:::::b   y:::::::::y        n::::n    n::::g::::::g    g:::::gh:::::h     h:::::h    //
//    s:::::ssss::::::h:::::h     h:::::o:::::ooooo:::::o     t::::::tttt:::::b:::::bbbbbb::::::b    y:::::::y         n::::n    n::::g:::::::ggggg:::::gh:::::h     h:::::h    //
//    s::::::::::::::sh:::::h     h:::::o:::::::::::::::o     tt::::::::::::::b::::::::::::::::b      y:::::y          n::::n    n::::ng::::::::::::::::gh:::::h     h:::::h    //
//     s:::::::::::ss h:::::h     h:::::hoo:::::::::::oo        tt:::::::::::tb:::::::::::::::b      y:::::y           n::::n    n::::n gg::::::::::::::gh:::::h     h:::::h    //
//      sssssssssss   hhhhhhh     hhhhhhh  ooooooooooo            ttttttttttt bbbbbbbbbbbbbbbb      y:::::y            nnnnnn    nnnnnn   gggggggg::::::ghhhhhhh     hhhhhhh    //
//                                                                                                 y:::::y                                        g:::::g                       //
//                                                                                                y:::::y                             gggggg      g:::::g                       //
//                                                                                               y:::::y                              g:::::gg   gg:::::g                       //
//                                                                                              y:::::y                                g::::::ggg:::::::g                       //
//                                                                                             yyyyyyy                                  gg:::::::::::::g                        //
//                                                                                                                                        ggg::::::ggg                          //
//                                                                                                                                           gggggg                             //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LP is ERC721Creator {
    constructor() ERC721Creator("Lollipop", "LP") {}
}
