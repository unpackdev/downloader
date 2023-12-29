// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sigrid’s Fables and Fantasies
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//                                                                                         dddddddd    //
//                       iiii                                            iiii              d::::::d    //
//                      i::::i                                          i::::i             d::::::d    //
//                       iiii                                            iiii              d::::::d    //
//                                                                                         d:::::d     //
//        ssssssssss   iiiiiii    ggggggggg   gggggrrrrr   rrrrrrrrr   iiiiiii     ddddddddd:::::d     //
//      ss::::::::::s  i:::::i   g:::::::::ggg::::gr::::rrr:::::::::r  i:::::i   dd::::::::::::::d     //
//    ss:::::::::::::s  i::::i  g:::::::::::::::::gr:::::::::::::::::r  i::::i  d::::::::::::::::d     //
//    s::::::ssss:::::s i::::i g::::::ggggg::::::ggrr::::::rrrrr::::::r i::::i d:::::::ddddd:::::d     //
//     s:::::s  ssssss  i::::i g:::::g     g:::::g  r:::::r     r:::::r i::::i d::::::d    d:::::d     //
//       s::::::s       i::::i g:::::g     g:::::g  r:::::r     rrrrrrr i::::i d:::::d     d:::::d     //
//          s::::::s    i::::i g:::::g     g:::::g  r:::::r             i::::i d:::::d     d:::::d     //
//    ssssss   s:::::s  i::::i g::::::g    g:::::g  r:::::r             i::::i d:::::d     d:::::d     //
//    s:::::ssss::::::si::::::ig:::::::ggggg:::::g  r:::::r            i::::::id::::::ddddd::::::dd    //
//    s::::::::::::::s i::::::i g::::::::::::::::g  r:::::r            i::::::i d:::::::::::::::::d    //
//     s:::::::::::ss  i::::::i  gg::::::::::::::g  r:::::r            i::::::i  d:::::::::ddd::::d    //
//      sssssssssss    iiiiiiii    gggggggg::::::g  rrrrrrr            iiiiiiii   ddddddddd   ddddd    //
//                                         g:::::g                                                     //
//                             gggggg      g:::::g                                                     //
//                             g:::::gg   gg:::::g                                                     //
//                              g::::::ggg:::::::g                                                     //
//                               gg:::::::::::::g                                                      //
//                                 ggg::::::ggg                                                        //
//                                    gggggg                                                           //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FABLE is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Sigrid’s Fables and Fantasies", "FABLE") {}
}
