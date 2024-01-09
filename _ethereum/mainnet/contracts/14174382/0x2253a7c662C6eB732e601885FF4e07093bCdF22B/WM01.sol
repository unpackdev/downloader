
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: We Love Colors
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//                                     ..,:;ii11ii;:,..                                                  ..:;;iiiii;;:,.                                                            //
//                               .;tLLLLLLLLLLLLLLLLLLLLLLfi,.                                    .:iLLLLLLLLLLLLLLLLLLLLLLLi,.                                                     //
//                           .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf;.                            .;fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf;.                                                 //
//                        ,tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL1,                      ,1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.                                              //
//                     .iLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.                .iLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL:                                            //
//                   .iLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf,            .tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;                                          //
//                  ;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf,        .tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL:                                        //
//                .fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt.    .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt.                                      //
//               ,LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL:  ,LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL,                                     //
//              :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLtiLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;                                    //
//             :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;                                   //
//            ,LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL:                                  //
//           .tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf.                                 //
//           ;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL1                                 //
//          .fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL.                                //
//          :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi                                //
//          iffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffLLLLLLLLLLLffffLLLLLLLLLLLLLLLLLLffffLLLLLLLLLLLLLLLLLLLLLLLLLLLt                                //
//                                                                                iLLLLLLf:           ;LLLLLLLL1,          .tLLLLLLLLLLLLLLLLLLLLLLL.                               //
//                                                                               tLLLLLt.               .1LLL:                ;LLLLLLLLLLLLLLLLLLLLL,                               //
//                                                                              1LLLLL:                   .i                   .fLLLLLLLLLLLLLLLLLLL,                               //
//          i1111111111111111111111111111111111111111111111111111111111111111111LLLLLi                                          .LLLLLLLLLLLLLLLLLLL.                               //
//          iLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf.                                           ;LLLLLLLLLLLLLLLLLf.                               //
//          :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL1                                            ,LLLLLLLLLLLLLLLLLi                                //
//           tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt                                            ,LLLLLLLLLLLLLLLLL.                                //
//            .................................................................;LLLLL,                                           1LLLLLLLLLLLLLLLLi                                 //
//                                                                             .tLLLLL.                                         ;LLLLLLLLLLLLLLLLf.                                 //
//                                                                              .LLLLLL:                                      .1LLLLLLLLLLLLLLLLf.                                  //
//                                                                               .fLLLLLL,                                   :LLLLLLLLLLLLLLLLLL.                                   //
//               ,LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;                              .iLLLLLLLLLLLLLLLLLLf.                                    //
//                .tLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf,                         :fLLLLLLLLLLLLLLLLLLL1                                      //
//                  :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt.                   ,fLLLLLLLLLLLLLLLLLLLLL,                                       //
//                    1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.             ,tLLLLLLLLLLLLLLLLLLLLLLi                                         //
//                                                                                          ,fLLLLLLLf,         iLLLLLLLLLLLLLLLLLLLLLLLt.                                          //
//                                                                                             :LLLLLLLL:    .1LLLLLLLLLLLLLLLLLLLLLLLt.                                            //
//                                                                                               .1LLLLLLf. ;LLLLLLLLLLLLLLLLLLLLLLL1.                                              //
//                             :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::tLLLLLLfLLLLLLLLLLLLLLLLLLLLLL;                                                 //
//                              ,fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf,                                                   //
//                                .;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.                                                     //
//                                   .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt,                                                        //
//                                      ,fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf,                                                           //
//                                        .:LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL:.                                                             //
//                                           .;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;.                                                                //
//                                              .iLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL;.                                                                   //
//                                                 .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.                                                                      //
//                                                    ,fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL1.                                                                         //
//                                                       :LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLt,                                                                            //
//                                                         .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLf:                                                                               //
//                                                            ,fLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLi.                                                                                 //
//                                                              .1LLLLLLLLLLLLLLLLLLLLLLLLLLLLf:                                                                                    //
//                                                                .iLLLLLLLLLLLLLLLLLLLLLLLLt.                                                                                      //
//                                                                   ;LLLLLLLLLLLLLLLLLLLLi.                                                                                        //
//                                                                     ;LLLLLLLLLLLLLLLL1.                                                                                          //
//                                                                      .1LLLLLLLLLLLLt.                                                                                            //
//                                                                        .fLLLLLLLLL:                                                                                              //
//                                                                          iLLLLLL1.                                                                                               //
//                                                                           ,LLLL;                                                                                                 //
//                                                                            .fL,                                                                                                  //
//                                                                             .,                                   www.welovecolors.com                                            //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WM01 is ERC721Creator {
    constructor() ERC721Creator("We Love Colors", "WM01") {}
}
