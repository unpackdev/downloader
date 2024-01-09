
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: meta_physical by doopy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                               //
//                                                                                                                                                                               //
//                                                                                                                                                                               //
//                                                                                                                                                                               //
//    DDDDDDDDDDDDD                                                                                                                         tttt         hhhhhhh                 //
//    D::::::::::::DDD                                                                                                                   ttt:::t         h:::::h                 //
//    D:::::::::::::::DD                                                                                                                 t:::::t         h:::::h                 //
//    DDD:::::DDDDD:::::D                                                                                                                t:::::t         h:::::h                 //
//      D:::::D    D:::::D    ooooooooooo      ooooooooooo   ppppp   pppppppppyyyyyyy           yyyyyyy            eeeeeeeeeeee    ttttttt:::::ttttttt    h::::h hhhhh           //
//      D:::::D     D:::::D oo:::::::::::oo  oo:::::::::::oo p::::ppp:::::::::py:::::y         y:::::y           ee::::::::::::ee  t:::::::::::::::::t    h::::hh:::::hhh        //
//      D:::::D     D:::::Do:::::::::::::::oo:::::::::::::::op:::::::::::::::::py:::::y       y:::::y           e::::::eeeee:::::eet:::::::::::::::::t    h::::::::::::::hh      //
//      D:::::D     D:::::Do:::::ooooo:::::oo:::::ooooo:::::opp::::::ppppp::::::py:::::y     y:::::y           e::::::e     e:::::etttttt:::::::tttttt    h:::::::hhh::::::h     //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::o p:::::p     p:::::p y:::::y   y:::::y            e:::::::eeeee::::::e      t:::::t          h::::::h   h::::::h    //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::o p:::::p     p:::::p  y:::::y y:::::y             e:::::::::::::::::e       t:::::t          h:::::h     h:::::h    //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::o p:::::p     p:::::p   y:::::y:::::y              e::::::eeeeeeeeeee        t:::::t          h:::::h     h:::::h    //
//      D:::::D    D:::::D o::::o     o::::oo::::o     o::::o p:::::p    p::::::p    y:::::::::y               e:::::::e                 t:::::t    tttttth:::::h     h:::::h    //
//    DDD:::::DDDDD:::::D  o:::::ooooo:::::oo:::::ooooo:::::o p:::::ppppp:::::::p     y:::::::y                e::::::::e                t::::::tttt:::::th:::::h     h:::::h    //
//    D:::::::::::::::DD   o:::::::::::::::oo:::::::::::::::o p::::::::::::::::p       y:::::y          ......  e::::::::eeeeeeee        tt::::::::::::::th:::::h     h:::::h    //
//    D::::::::::::DDD      oo:::::::::::oo  oo:::::::::::oo  p::::::::::::::pp       y:::::y           .::::.   ee:::::::::::::e          tt:::::::::::tth:::::h     h:::::h    //
//    DDDDDDDDDDDDD           ooooooooooo      ooooooooooo    p::::::pppppppp        y:::::y            ......     eeeeeeeeeeeeee            ttttttttttt  hhhhhhh     hhhhhhh    //
//                                                            p:::::p               y:::::y                                                                                      //
//                                                            p:::::p              y:::::y                                                                                       //
//                                                           p:::::::p            y:::::y                                                                                        //
//                                                           p:::::::p           y:::::y                                                                                         //
//                                                           p:::::::p          yyyyyyy                                                                                          //
//                                                           ppppppppp                                                                                                           //
//                                                                                                                                                                               //
//                                                                                                                                                                               //
//                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RLGN is ERC721Creator {
    constructor() ERC721Creator("meta_physical by doopy", "RLGN") {}
}
