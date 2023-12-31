// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fields of Color - by CryptoBauhaus
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    Generative art by CryptoBauhaus                  //
//                                                     //
//    /\ /\                                            //
//                       |||| ||||                     //
//                      /\ /\ /\ /\                    //
//                     |||| |||| ||||                  //
//                    \\\/ \\\/ \\\/                   //
//                   ____ ____ ____                    //
//                  /    \ /    \ /    \               //
//                 |      |      |      |              //
//                |   /\  |   /\  |   /\  |            //
//               |  ||||  |  ||||  |  ||||  |          //
//              | /\ /\ /\ /\ /\ /\ /\ /\ |            //
//             |||| |||| |||| |||| |||| ||||           //
//            \\\/ \\\/ \\\/ \\\/ \\\/ \\\/            //
//                                              ```    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract fieldsofcolorcb is ERC721Creator {
    constructor() ERC721Creator("Fields of Color - by CryptoBauhaus", "fieldsofcolorcb") {}
}
