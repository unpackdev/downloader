
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dance of the Masses
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                               .                            //
//                            ;kOc.                                            ;kOc.                          //
//                          ;kNWNN0c.                                        ;kNWWN0c.                        //
//                        ;kNWWWWNWN0c.                                    ;kNWNWWWWN0c.                      //
//                      ;kNWNWWWWWWWWN0c.                                ;kNWNWWWWWNWWN0c.                    //
//                    ;kNWNWWWWWWWWWWNWNOc.                            ;kNWNWWWWNWWWWWWWN0c.                  //
//                 .cxKWNWNNWWWWWWWWWWNNWNOc.                        ;kNWWNWWWWWWWNWWWWWNNKko.                //
//                ;kX00NNNNNWWWWWWWWWNNWWWWN0c.                    ;kNWWWWWWWWWNWWWWWWWNNXKKN0c.              //
//              ;kNWWWNNXKKXWWWWWWWWWWWNWWWWWN0c.                ;kNWNWWWWWWWWWWWWWWWXKKXNNWWWN0c.            //
//            ;kNWWWWWWNNOoOWWWWWWWWWWWNWWWWWWWN0c.            ;kNWNWWWWWWWWWWWWWWWNW0dOXNWWWWNWN0c.          //
//         .;kNWNNWWWWWWWNNNWWWWWWWWWWWWWWWWWWWWWN0c.        ;kNWWNWWWWWWWWWWWWWWNWWWNNNWWWWWWWWWWN0c.        //
//        ;kNWWWWWWWWWWNWWWNWWWWWWWWWWNWWWWWWWWWWWWN0c.    ;kNWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWWWWWWWWN0c.      //
//       :KWNWWWWWWWWWWWWWWWWWWWN0OkOXNWWWNWWWWWWWWWWN0c,:kNWWWWWWWWWWWWWWNX0kk0XWWWNWWWWWWWWWWWNWWWNWNo.     //
//        ;xXWWWWWWWWWWWWWWWWWWNOooolo0WWWWWWWWWWNWWWNWWNWWWWWWWWWWWWWWWNWXdloookNWWWWWWWWWWWWWWWWWWNO:.      //
//          ,xXWNWNNWWWWWWWWWWWN0dll:cONNWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWWWW0l:cldONWNWWWWWWWWWWWWNWNO:.        //
//            ;kXWNWWWWWWWWWWWWWNX0kk0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKkk0XNWWWWWWWWWNWWWNWNO:.          //
//              ;xXWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWNO:.            //
//                ,xXWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWNO:.              //
//                  ,kXWNWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:.                //
//                    ;xXWNWWWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWNO:.                  //
//                      ,xXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:.                    //
//                        ,xXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:.                      //
//                          ,xXWNWWNWWWWWWWWWWWNWWWWNkl:::lxXWWWWWWWWWWWWWWWWWWWWWNO:.                        //
//                            ;xXWNWNWWWWWWWWWWWWNWXl       ;0WNWWWWWWWWWWWWWWWWNO:.                          //
//                             .xNWNNWWWWWWWWWWNWNWO.       .dWNWWWWWWWWWWWWWWWWO,                            //
//                            ;kNWNWWWWWWWWWWWWWWNWXl.      :0WNWWWWWWWWWWWWWWWWN0c.                          //
//                          ;kNWNWWWWWWWWWWWWWWNWNNWNOoccclkXWNWWWWWWWWWWWWWWWWWNWN0c.                        //
//                        ;kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0c.                      //
//                      ;kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0c.                    //
//                    ;kNWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWN0c.                  //
//                  ;kNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0c.                //
//                ;kNWWWWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0c.              //
//              ;kNWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWN0c.            //
//            ;kNWWWWWWWWWWWWWWWN0kxdONWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWN0xxOKNWWWWWWWWWWWWWNWN0c.          //
//          ;kNWWWWWWWWWWWWWWWWNkoll:l0WNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWKl:llokNWWWWWWWWWWWWWWWWN0c.        //
//        ;kNWNWWNNWWWWWWWWWWWWXkooookXWWWWWWWWWWWWWWWWNNNWWWWWWWWWNWWWWNWXkloookXWNWWWWNWWWWWWWWWWWN0c.      //
//       :KWNWWWWNNWWWWWWWWWWWWNNK00KNWWWWWWWWWWWWWNWNOc':xXWWWWWWWWWWWWWWWNKOO0XWWWWWWWWWWWWWWWWWWWNWNo.     //
//        ;kXWWWNWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWNO:.    ,xXWNWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWNOc.      //
//          ;kNWNNWWWWWWNXKNWWWWWWWWWWWWNNWWWWWWWNO:.        ;xXWNWWNWWWWWWWWWWWWWWWWNXXNWWWWWWWNWNOc.        //
//            ;kXWNWWWWNXxdKWNWWWWWNWWWWWWWWWNWNO:.            ,xXWNWWWWWNWWWWWNWWWWWXddKNWWWWWWNOc.          //
//              ;kXWWWNXXXXNWWWWWWWWWWWWWWWNWNO:.                ,xXWWWWWWWWWWWWWWWWWNXXXXNNWWNOc.            //
//                ;kX00NWWWWWWWWWWWWWWWWWWWNO:.                    ,xXWWWWNWWWWWWWWWWWWWWNX0K0c.              //
//                 .:xKWWWWWNWWWWWWWWWWWWNO:.                        ,xXWWWWWWWWWWWWWWWWWWNkl'                //
//                    ;kXWWWNWWWWWWWWNWNO:.                            ;xXWNWWWWWWWNWWNWNOc.                  //
//                      ;kXWNWWWWWWNWNO:.                                ,xXWWWWWWWWNWNOc.                    //
//                        ;kXWNWWWWNO:.                                    ,xXWNWWNWNOc.                      //
//                          ;kNWWNO:.                                        ,xXWNNOc.                        //
//                            ;xk:.                                            ,xk:.                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOTM is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
