// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dr.Otto
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                dddddddd                                                                                                                                              //
//                d::::::d                                                                          tttt                        tttt                                    //
//                d::::::d                                                                       ttt:::t                     ttt:::t                                    //
//                d::::::d                                                                       t:::::t                     t:::::t                                    //
//                d:::::d                                                                        t:::::t                     t:::::t                                    //
//        ddddddddd:::::d      rrrrr   rrrrrrrrr                        ooooooooooo        ttttttt:::::ttttttt         ttttttt:::::ttttttt            ooooooooooo       //
//      dd::::::::::::::d      r::::rrr:::::::::r                     oo:::::::::::oo      t:::::::::::::::::t         t:::::::::::::::::t          oo:::::::::::oo     //
//     d::::::::::::::::d      r:::::::::::::::::r                   o:::::::::::::::o     t:::::::::::::::::t         t:::::::::::::::::t         o:::::::::::::::o    //
//    d:::::::ddddd:::::d      rr::::::rrrrr::::::r                  o:::::ooooo:::::o     tttttt:::::::tttttt         tttttt:::::::tttttt         o:::::ooooo:::::o    //
//    d::::::d    d:::::d       r:::::r     r:::::r                  o::::o     o::::o           t:::::t                     t:::::t               o::::o     o::::o    //
//    d:::::d     d:::::d       r:::::r     rrrrrrr                  o::::o     o::::o           t:::::t                     t:::::t               o::::o     o::::o    //
//    d:::::d     d:::::d       r:::::r                              o::::o     o::::o           t:::::t                     t:::::t               o::::o     o::::o    //
//    d:::::d     d:::::d       r:::::r                              o::::o     o::::o           t:::::t    tttttt           t:::::t    tttttt     o::::o     o::::o    //
//    d::::::ddddd::::::dd      r:::::r                              o:::::ooooo:::::o           t::::::tttt:::::t           t::::::tttt:::::t     o:::::ooooo:::::o    //
//     d:::::::::::::::::d      r:::::r                  ......      o:::::::::::::::o           tt::::::::::::::t           tt::::::::::::::t     o:::::::::::::::o    //
//      d:::::::::ddd::::d      r:::::r                  .::::.       oo:::::::::::oo              tt:::::::::::tt             tt:::::::::::tt      oo:::::::::::oo     //
//       ddddddddd   ddddd      rrrrrrr                  ......         ooooooooooo                  ttttttttttt                 ttttttttttt          ooooooooooo       //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OTTO is ERC1155Creator {
    constructor() ERC1155Creator("Dr.Otto", "OTTO") {}
}
