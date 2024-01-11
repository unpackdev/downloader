
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conte Art Drops
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                               dddddddd                             //
//            GGGGGGGGGGGGG                                            tttt            iiii          tttt                                        d::::::d                             //
//         GGG::::::::::::G                                         ttt:::t           i::::i      ttt:::t                                        d::::::d                             //
//       GG:::::::::::::::G                                         t:::::t            iiii       t:::::t                                        d::::::d                             //
//      G:::::GGGGGGGG::::G                                         t:::::t                       t:::::t                                        d:::::d                              //
//     G:::::G       GGGGGGrrrrr   rrrrrrrrr   aaaaaaaaaaaaa  ttttttt:::::ttttttt    iiiiiiittttttt:::::ttttttt    uuuuuu    uuuuuu      ddddddddd:::::d     eeeeeeeeeeee             //
//    G:::::G              r::::rrr:::::::::r  a::::::::::::a t:::::::::::::::::t    i:::::it:::::::::::::::::t    u::::u    u::::u    dd::::::::::::::d   ee::::::::::::ee           //
//    G:::::G              r:::::::::::::::::r aaaaaaaaa:::::at:::::::::::::::::t     i::::it:::::::::::::::::t    u::::u    u::::u   d::::::::::::::::d  e::::::eeeee:::::ee         //
//    G:::::G    GGGGGGGGGGrr::::::rrrrr::::::r         a::::atttttt:::::::tttttt     i::::itttttt:::::::tttttt    u::::u    u::::u  d:::::::ddddd:::::d e::::::e     e:::::e         //
//    G:::::G    G::::::::G r:::::r     r:::::r  aaaaaaa:::::a      t:::::t           i::::i      t:::::t          u::::u    u::::u  d::::::d    d:::::d e:::::::eeeee::::::e         //
//    G:::::G    GGGGG::::G r:::::r     rrrrrrraa::::::::::::a      t:::::t           i::::i      t:::::t          u::::u    u::::u  d:::::d     d:::::d e:::::::::::::::::e          //
//    G:::::G        G::::G r:::::r           a::::aaaa::::::a      t:::::t           i::::i      t:::::t          u::::u    u::::u  d:::::d     d:::::d e::::::eeeeeeeeeee           //
//     G:::::G       G::::G r:::::r          a::::a    a:::::a      t:::::t    tttttt i::::i      t:::::t    ttttttu:::::uuuu:::::u  d:::::d     d:::::d e:::::::e                    //
//      G:::::GGGGGGGG::::G r:::::r          a::::a    a:::::a      t::::::tttt:::::ti::::::i     t::::::tttt:::::tu:::::::::::::::uud::::::ddddd::::::dde::::::::e                   //
//       GG:::::::::::::::G r:::::r          a:::::aaaa::::::a      tt::::::::::::::ti::::::i     tt::::::::::::::t u:::::::::::::::u d:::::::::::::::::d e::::::::eeeeeeee           //
//         GGG::::::GGG:::G r:::::r           a::::::::::aa:::a       tt:::::::::::tti::::::i       tt:::::::::::tt  uu::::::::uu:::u  d:::::::::ddd::::d  ee:::::::::::::e           //
//            GGGGGG   GGGG rrrrrrr            aaaaaaaaaa  aaaa         ttttttttttt  iiiiiiii         ttttttttttt      uuuuuuuu  uuuu   ddddddddd   ddddd    eeeeeeeeeeeeee           //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    xxxxxxx      xxxxxxx                                                                                                                                                            //
//     x:::::x    x:::::x                                                                                                                                                             //
//      x:::::x  x:::::x                                                                                                                                                              //
//       x:::::xx:::::x                                                                                                                                                               //
//        x::::::::::x                                                                                                                                                                //
//         x::::::::x                                                                                                                                                                 //
//         x::::::::x                                                                                                                                                                 //
//        x::::::::::x                                                                                                                                                                //
//       x:::::xx:::::x                                                                                                                                                               //
//      x:::::x  x:::::x                                                                                                                                                              //
//     x:::::x    x:::::x                                                                                                                                                             //
//    xxxxxxx      xxxxxxx                                                                                                                                                            //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                   AAA                                           tttt                                                                                                               //
//                  A:::A                                       ttt:::t                                                                                                               //
//                 A:::::A                                      t:::::t                                                                                                               //
//                A:::::::A                                     t:::::t                                                                                                               //
//               A:::::::::A          rrrrr   rrrrrrrrr   ttttttt:::::ttttttt                                                                                                         //
//              A:::::A:::::A         r::::rrr:::::::::r  t:::::::::::::::::t                                                                                                         //
//             A:::::A A:::::A        r:::::::::::::::::r t:::::::::::::::::t                                                                                                         //
//            A:::::A   A:::::A       rr::::::rrrrr::::::rtttttt:::::::tttttt                                                                                                         //
//           A:::::A     A:::::A       r:::::r     r:::::r      t:::::t                                                                                                               //
//          A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr      t:::::t                                                                                                               //
//         A:::::::::::::::::::::A     r:::::r                  t:::::t                                                                                                               //
//        A:::::AAAAAAAAAAAAA:::::A    r:::::r                  t:::::t    tttttt                                                                                                     //
//       A:::::A             A:::::A   r:::::r                  t::::::tttt:::::t                                                                                                     //
//      A:::::A               A:::::A  r:::::r                  tt::::::::::::::t                                                                                                     //
//     A:::::A                 A:::::A r:::::r                    tt:::::::::::tt                                                                                                     //
//    AAAAAAA                   AAAAAAArrrrrrr                      ttttttttttt                                                                                                       //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CAD is ERC721Creator {
    constructor() ERC721Creator("Conte Art Drops", "CAD") {}
}
