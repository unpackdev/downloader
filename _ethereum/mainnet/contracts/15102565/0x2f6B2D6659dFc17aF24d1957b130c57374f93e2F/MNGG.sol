
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monogaga
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                             .......                                            //
//                                                                          'lxOKKXXKKOkdl;.                                      //
//                                               ...''''..                .oXWWNNNNNNNNWWWWXOd:.                                  //
//                                         .':oxO0KXNNNNXKOdc'            :XWNWWWWWWWWWWWWWNNWNKx:.                               //
//                                      .:d0XWWWNNNNNNWNNWWWWXkc.         lNWNWWWWWWWWWWWWWWWWNNWNKo'                             //
//                                   .;dKNWNNWWWWWNWWWWWWWNWWNWN0l,.      ;XWNWWWWWWWWNWWWWWWWWWNWWWXd'                           //
//                                 .:ONWNWWWWNWWWNNWWWWWNWWWWWNNWNN0:      oXWNWWWWWWWWWWWWWWWWWWWWWNWKc.                         //
//                                :ONWNWWWWWWWWWWWWWWWWWWWWWWWWWWNNWXd.     cXWNWWWWWWWWWWWWWWWWWWWWWNWNd.                        //
//                              'xNWNWWWWWWWNWWWWWWWWWWWWWWWWNWWWWWWWNO'     ,ONWNNWWWWWWWWWWWWNWWWWWWNWNo                        //
//                             cKWWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWNW0;     .dXWWWNWWWWWWWWWWWWWWWWWWNW0,                       //
//                           .dXWWWNWWWWWNWWWWWWWWWWWWWWWWWWWWWNWWWWWWNWK:      ;OWWWWWWWWWWWWWWWNNWWWWNWK,                       //
//                          .xNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWX:      .dXWNWWWWWWWWWWWNWWWWWNWO.                       //
//                         .xNWWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK:       :0WWWWWWWNWWWWWWWWWWWNo                        //
//                        .xNWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWK:       .kNWNNWWWWWWWWWWWNNWk.                        //
//                        oNWNNWWWWNWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWNWWNNWK:       .dNWNWWWWWWNWWWWWWO'                         //
//                       :XWNWWWWWWWWWWWWWWWWWWWWWWNNNWWWWWWWWWWWWWWWWWWNWNNWK:       .dNWWWWWWNNWWNWNx.                          //
//                      .OWNWWWWWWWWWWWWWWWWWWWWWWNNNWWWWWWWWWWWNNNWWWNWWNWWNWK:       '0WNNWWWNNNNW0c.                           //
//                      lNWNWWWWWWWWWWWWWWWWWWWNWWWNX0OkxddddxkO0KXNNWWWWWNWWWWXl.     .xWNWNWWWWWKo.                             //
//                     '0WNNWWWWWWWWWWWWWNNWWWWXOo:,..          ...';cokKNWWWNNWNx'    .OWNWWNWNKo.                               //
//                     cNWNWWWWWWWWWWWWWWWWWWKo,                        .;o0NWNWWWKxc;:kNWNWWN0c.                                 //
//                    .xWNNWWNWWWWWWWWWWWWNNk'                             .:ONWWNNWWWWWWNWNO:.                                   //
//                    .OWNWWWWWWWWWWWWWWNNWK,                                '0WNWNNWWWWNWKc.                                     //
//                    ,KWNWWWWWWWWWWWWWWNNW0'                                cKWNWNNWWWNWX:                                       //
//                    ;KWNWWWWWWWWWWWWWWWNWNd.                            .:kXWWWNKKNWWNWX:                                       //
//                    ,KWNNWWNWWWWWWWNWWWWNWNk:.                      .,lxKNWWN0l,..:0WNWW0:                                      //
//                    .OWNNWWNWWWWWWWWWWWWWWWWN0dc,..         ..';cldkKNWWNNWXo.    .OWNNNWXx;                                    //
//                    .dWWNWWWWWWWWWWWWWWWWWWWWWWWNX0OkxdddxkO0XNWWWWWNWWWWW0;     .dNWWWWWWWNk:.                                 //
//                     ;XWNWWWWWWWWWWWWWWWWWWWWWWNNNNNWWWWWWWNNNNNWWWWNWWNNk'     'kNWNWWWWWWNWN0o'                               //
//                     .xWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWNx.    .lKWWWNNWWWWWWNNWWXx,                             //
//                      ,0WNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNo.    ,kNWNWWWWWWWWWWWWWWNWXd.                           //
//                       :XWNWWNWWNWWNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWXl.    cKWNWWWWWWWWNWWWWWWWWNNW0,                          //
//                        cXWNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWNWKc     cXWNNWWNWWWWWWWWWWWWWWWNNW0'                         //
//                         cKWNNNNWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNW0;     ,KWNWWWWWNWWWWWWWWWWWWWWWNWNo                         //
//                          ;ONWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWNk'      dWNWWNWWWWWWWWWWWWWWWWWWWWNWx.                        //
//                           .dXWNWWWWWWNWWNWWWWWWWWWWWWNWWWWWNNWX0o.      .xWNWWWWWWWWWWWWWWWWWWNWWWWWNl                         //
//                             ,kNWNWWWWWWWWWWWWWWWWWWWWWWWWWNWNO;.         oNWWWNNWNNWWWWWWWWWWWWWWWNW0'                         //
//                               ;xXWWNNNNNWWWWWWWWWNWNWWNWWNWKl.           .kNNWNNWNWWWWWWWWWWWWWNNNW0;                          //
//                                 'lOXWWNNWWWWWWWWWWNWWWNWNKo.              .lKWWNNWWWWWWWWWWNWWNWWXd'                           //
//                                    'cdOXNWWWWNNNNWWWWNKxc.                  .ckKNWWWWWWWWWWWWNKkl'                             //
//                                       ..,codxkkOOkxdl;.                        .,codxkkkxxdoc,.                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MNGG is ERC721Creator {
    constructor() ERC721Creator("Monogaga", "MNGG") {}
}
