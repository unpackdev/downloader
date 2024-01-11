
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fatih Caliskan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//    FFFFFFFFFFFFFFFFFFFFFF                           tttt            iiii  hhhhhhh                                                     //
//    F                    F                        ttt:::t           i::::i h:::::h                                                     //
//    F                    F                        t:::::t            iiii  h:::::h                                                     //
//    FF      FFFFFFFFF    F                        t:::::t                  h:::::h                                                     //
//      F     F       FFFFFF  aaaaaaaaaaaaa   ttttttt:::::ttttttt    iiiiiii  h::::h hhhhh                                               //
//      F     F               a::::::::::::a  t:::::::::::::::::t    i:::::i  h::::hh:::::hhh                                            //
//      F      FFFFFFFFFF     aaaaaaaaa:::::a t:::::::::::::::::t     i::::i  h::::::::::::::hh                                          //
//      F               F              a::::a tttttt:::::::tttttt     i::::i  h:::::::hhh::::::h                                         //
//      F               F       aaaaaaa:::::a       t:::::t           i::::i  h::::::h   h::::::h                                        //
//      F      FFFFFFFFFF     aa::::::::::::a       t:::::t           i::::i  h:::::h     h:::::h                                        //
//      F     F              a::::aaaa::::::a       t:::::t           i::::i  h:::::h     h:::::h                                        //
//      F     F             a::::a    a:::::a       t:::::t    tttttt i::::i  h:::::h     h:::::h                                        //
//      F     F             a::::a    a:::::a       t::::::tttt:::::ti::::::i h:::::h     h:::::h                                        //
//      F     F             a:::::aaaa::::::a       tt::::::::::::::ti::::::i h:::::h     h:::::h                                        //
//      F     F              a::::::::::aa:::a        tt:::::::::::tti::::::i h:::::h     h:::::h                                        //
//      FFFFFFF               aaaaaaaaaa  aaaa          ttttttttttt  iiiiiiii hhhhhhh     hhhhhhh                                        //
//                                                                                                                                       //
//            CCCCCCCCCCCCC                  lllllll   iiii                   kkkkkkkk                                                   //
//         CCC            C                  l:::::l  i::::i                  k::::::k                                                   //
//       CC               C                  l:::::l   iiii                   k::::::k                                                   //
//      C     CCCCCCCC    C                  l:::::l                          k::::::k                                                   //
//     C     C       CCCCCC  aaaaaaaaaaaaa    l::::l iiiiiii     ssssssssss    k:::::k    kkkkkkk  aaaaaaaaaaaaa   nnnn  nnnnnnnn        //
//    C     C                a::::::::::::a   l::::l i:::::i   ss::::::::::s   k:::::k   k:::::k   a::::::::::::a  n:::nn::::::::nn      //
//    C     C                aaaaaaaaa:::::a  l::::l  i::::i ss:::::::::::::s  k:::::k  k:::::k    aaaaaaaaa:::::a n::::::::::::::nn     //
//    C     C                         a::::a  l::::l  i::::i s::::::ssss:::::s k:::::k k:::::k              a::::a nn:::::::::::::::n    //
//    C     C                  aaaaaaa:::::a  l::::l  i::::i  s:::::s  ssssss  k::::::k:::::k        aaaaaaa:::::a   n:::::nnnn:::::n    //
//    C     C                aa::::::::::::a  l::::l  i::::i    s::::::s       k:::::::::::k       aa::::::::::::a   n::::n    n::::n    //
//    C     C               a::::aaaa::::::a  l::::l  i::::i       s::::::s    k:::::::::::k      a::::aaaa::::::a   n::::n    n::::n    //
//     C     C       CCCCCCa::::a    a:::::a  l::::l  i::::i ssssss   s:::::s  k::::::k:::::k    a::::a    a:::::a   n::::n    n::::n    //
//      C     CCCCCCCC    Ca::::a    a:::::a l::::::li::::::is:::::ssss::::::sk::::::k k:::::k   a::::a    a:::::a   n::::n    n::::n    //
//       CC               Ca:::::aaaa::::::a l::::::li::::::is::::::::::::::s k::::::k  k:::::k  a:::::aaaa::::::a   n::::n    n::::n    //
//         CCC            C a::::::::::aa:::al::::::li::::::i s:::::::::::ss  k::::::k   k:::::k  a::::::::::aa:::a  n::::n    n::::n    //
//            CCCCCCCCCCCCC  aaaaaaaaaa  aaaalllllllliiiiiiii  sssssssssss    kkkkkkkk    kkkkkkk  aaaaaaaaaa  aaaa  nnnnnn    nnnnnn    //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FC is ERC721Creator {
    constructor() ERC721Creator("Fatih Caliskan", "FC") {}
}
