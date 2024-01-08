
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kilroy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//    KKKKKKKKK    KKKKKKK  iiii  lllllll                                                                                                                                                             //
//    K:::::::K    K:::::K i::::i l:::::l                                                                                                                                                             //
//    K:::::::K    K:::::K  iiii  l:::::l                                                                                                                                                             //
//    K:::::::K   K::::::K        l:::::l                                                                                                                                                             //
//    KK::::::K  K:::::KKKiiiiiii  l::::lrrrrr   rrrrrrrrr      ooooooooooo yyyyyyy           yyyyyyy                                                                                                 //
//      K:::::K K:::::K   i:::::i  l::::lr::::rrr:::::::::r   oo:::::::::::ooy:::::y         y:::::y                                                                                                  //
//      K::::::K:::::K     i::::i  l::::lr:::::::::::::::::r o:::::::::::::::oy:::::y       y:::::y                                                                                                   //
//      K:::::::::::K      i::::i  l::::lrr::::::rrrrr::::::ro:::::ooooo:::::o y:::::y     y:::::y                                                                                                    //
//      K:::::::::::K      i::::i  l::::l r:::::r     r:::::ro::::o     o::::o  y:::::y   y:::::y                                                                                                     //
//      K::::::K:::::K     i::::i  l::::l r:::::r     rrrrrrro::::o     o::::o   y:::::y y:::::y                                                                                                      //
//      K:::::K K:::::K    i::::i  l::::l r:::::r            o::::o     o::::o    y:::::y:::::y                                                                                                       //
//    KK::::::K  K:::::KKK i::::i  l::::l r:::::r            o::::o     o::::o     y:::::::::y                                                                                                        //
//    K:::::::K   K::::::Ki::::::il::::::lr:::::r            o:::::ooooo:::::o      y:::::::y                                                                                                         //
//    K:::::::K    K:::::Ki::::::il::::::lr:::::r            o:::::::::::::::o       y:::::y                                                                                                          //
//    K:::::::K    K:::::Ki::::::il::::::lr:::::r             oo:::::::::::oo       y:::::y                                                                                                           //
//    KKKKKKKKK    KKKKKKKiiiiiiiillllllllrrrrrrr               ooooooooooo        y:::::y                                                                                                            //
//                                                                                y:::::y                                                                                                             //
//                                                                               y:::::y                                                                                                              //
//                                                                              y:::::y                                                                                                               //
//                                                                             y:::::y                                                                                                                //
//                                                                            yyyyyyy                                                                                                                 //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//    WWWWWWWW                           WWWWWWWW                                                                                                                                                     //
//    W::::::W                           W::::::W                                                                                                                                                     //
//    W::::::W                           W::::::W                                                                                                                                                     //
//    W::::::W                           W::::::W                                                                                                                                                     //
//     W:::::W           WWWWW           W:::::Waaaaaaaaaaaaa      ssssssssss                                                                                                                         //
//      W:::::W         W:::::W         W:::::W a::::::::::::a   ss::::::::::s                                                                                                                        //
//       W:::::W       W:::::::W       W:::::W  aaaaaaaaa:::::ass:::::::::::::s                                                                                                                       //
//        W:::::W     W:::::::::W     W:::::W            a::::as::::::ssss:::::s                                                                                                                      //
//         W:::::W   W:::::W:::::W   W:::::W      aaaaaaa:::::a s:::::s  ssssss                                                                                                                       //
//          W:::::W W:::::W W:::::W W:::::W     aa::::::::::::a   s::::::s                                                                                                                            //
//           W:::::W:::::W   W:::::W:::::W     a::::aaaa::::::a      s::::::s                                                                                                                         //
//            W:::::::::W     W:::::::::W     a::::a    a:::::assssss   s:::::s                                                                                                                       //
//             W:::::::W       W:::::::W      a::::a    a:::::as:::::ssss::::::s                                                                                                                      //
//              W:::::W         W:::::W       a:::::aaaa::::::as::::::::::::::s                                                                                                                       //
//               W:::W           W:::W         a::::::::::aa:::as:::::::::::ss                                                                                                                        //
//                WWW             WWW           aaaaaaaaaa  aaaa sssssssssss                                                                                                                          //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//    HHHHHHHHH     HHHHHHHHH                                                                                                                                                                         //
//    H:::::::H     H:::::::H                                                                                                                                                                         //
//    H:::::::H     H:::::::H                                                                                                                                                                         //
//    HH::::::H     H::::::HH                                                                                                                                                                         //
//      H:::::H     H:::::H      eeeeeeeeeeee    rrrrr   rrrrrrrrr       eeeeeeeeeeee                                                                                                                 //
//      H:::::H     H:::::H    ee::::::::::::ee  r::::rrr:::::::::r    ee::::::::::::ee                                                                                                               //
//      H::::::HHHHH::::::H   e::::::eeeee:::::eer:::::::::::::::::r  e::::::eeeee:::::ee                                                                                                             //
//      H:::::::::::::::::H  e::::::e     e:::::err::::::rrrrr::::::re::::::e     e:::::e                                                                                                             //
//      H:::::::::::::::::H  e:::::::eeeee::::::e r:::::r     r:::::re:::::::eeeee::::::e                                                                                                             //
//      H::::::HHHHH::::::H  e:::::::::::::::::e  r:::::r     rrrrrrre:::::::::::::::::e                                                                                                              //
//      H:::::H     H:::::H  e::::::eeeeeeeeeee   r:::::r            e::::::eeeeeeeeeee                                                                                                               //
//      H:::::H     H:::::H  e:::::::e            r:::::r            e:::::::e                                                                                                                        //
//    HH::::::H     H::::::HHe::::::::e           r:::::r            e::::::::e                                                                                                                       //
//    H:::::::H     H:::::::H e::::::::eeeeeeee   r:::::r             e::::::::eeeeeeee                                                                                                               //
//    H:::::::H     H:::::::H  ee:::::::::::::e   r:::::r              ee:::::::::::::e                                                                                                               //
//    HHHHHHHHH     HHHHHHHHH    eeeeeeeeeeeeee   rrrrrrr                eeeeeeeeeeeeee                                                                                                               //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                     .      .      _     _         !!!       #   ___              .                                                                                                                 //
//         /777      .  .:::.      o' \,=./ `o    `  _ _  '    #  <_*_>         ,-_-|                                                                                                                 //
//        (o o)        :(o o):  .     (o o)      -  (OXO)  -   #  (o o)        ([o o])                                                                                                                //
//    ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo--8---(_)--Ooo-ooO--(_)--Ooo-                                                                                                            //
//                     |                                                                                                                                                                              //
//         )|(         |.===.       `  _ ,  '                                                                                                                                                         //
//        (o o)        {}o o{}     -  (o)o)  -                                                                                                                                                        //
//    ooO--(_)--Ooo-ooO--(_)--Ooo--ooO'(_)--Ooo-                                                                                                                                                      //
//                       |"|           !!!           |"|                                                                                                                                              //
//         ***          _|_|_       `  _ _  '       _|_|_                                                                                                                                             //
//        (o o)         (o o)      -  (OXO)  -      (o o)                                                                                                                                             //
//    ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-                                                                                                                                        //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
//                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Kilroy is ERC721Creator {
    constructor() ERC721Creator("Kilroy", "Kilroy") {}
}
