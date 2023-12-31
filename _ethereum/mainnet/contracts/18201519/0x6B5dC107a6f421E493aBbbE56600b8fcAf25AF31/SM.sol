// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slimez Machine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//       SSSSSSSSSSSSSSS lllllll   iiii                                                                    MMMMMMMM               MMMMMMMM                                    hhhhhhh               iiii                                           //
//     SS:::::::::::::::Sl:::::l  i::::i                                                                   M:::::::M             M:::::::M                                    h:::::h              i::::i                                          //
//    S:::::SSSSSS::::::Sl:::::l   iiii                                                                    M::::::::M           M::::::::M                                    h:::::h               iiii                                           //
//    S:::::S     SSSSSSSl:::::l                                                                           M:::::::::M         M:::::::::M                                    h:::::h                                                              //
//    S:::::S             l::::l iiiiiii    mmmmmmm    mmmmmmm       eeeeeeeeeeee    zzzzzzzzzzzzzzzzz     M::::::::::M       M::::::::::M  aaaaaaaaaaaaa      cccccccccccccccch::::h hhhhh       iiiiiiinnnn  nnnnnnnn        eeeeeeeeeeee        //
//    S:::::S             l::::l i:::::i  mm:::::::m  m:::::::mm   ee::::::::::::ee  z:::::::::::::::z     M:::::::::::M     M:::::::::::M  a::::::::::::a   cc:::::::::::::::ch::::hh:::::hhh    i:::::in:::nn::::::::nn    ee::::::::::::ee      //
//     S::::SSSS          l::::l  i::::i m::::::::::mm::::::::::m e::::::eeeee:::::eez::::::::::::::z      M:::::::M::::M   M::::M:::::::M  aaaaaaaaa:::::a c:::::::::::::::::ch::::::::::::::hh   i::::in::::::::::::::nn  e::::::eeeee:::::ee    //
//      SS::::::SSSSS     l::::l  i::::i m::::::::::::::::::::::me::::::e     e:::::ezzzzzzzz::::::z       M::::::M M::::M M::::M M::::::M           a::::ac:::::::cccccc:::::ch:::::::hhh::::::h  i::::inn:::::::::::::::ne::::::e     e:::::e    //
//        SSS::::::::SS   l::::l  i::::i m:::::mmm::::::mmm:::::me:::::::eeeee::::::e      z::::::z        M::::::M  M::::M::::M  M::::::M    aaaaaaa:::::ac::::::c     ccccccch::::::h   h::::::h i::::i  n:::::nnnn:::::ne:::::::eeeee::::::e    //
//           SSSSSS::::S  l::::l  i::::i m::::m   m::::m   m::::me:::::::::::::::::e      z::::::z         M::::::M   M:::::::M   M::::::M  aa::::::::::::ac:::::c             h:::::h     h:::::h i::::i  n::::n    n::::ne:::::::::::::::::e     //
//                S:::::S l::::l  i::::i m::::m   m::::m   m::::me::::::eeeeeeeeeee      z::::::z          M::::::M    M:::::M    M::::::M a::::aaaa::::::ac:::::c             h:::::h     h:::::h i::::i  n::::n    n::::ne::::::eeeeeeeeeee      //
//                S:::::S l::::l  i::::i m::::m   m::::m   m::::me:::::::e              z::::::z           M::::::M     MMMMM     M::::::Ma::::a    a:::::ac::::::c     ccccccch:::::h     h:::::h i::::i  n::::n    n::::ne:::::::e               //
//    SSSSSSS     S:::::Sl::::::li::::::im::::m   m::::m   m::::me::::::::e            z::::::zzzzzzzz     M::::::M               M::::::Ma::::a    a:::::ac:::::::cccccc:::::ch:::::h     h:::::hi::::::i n::::n    n::::ne::::::::e              //
//    S::::::SSSSSS:::::Sl::::::li::::::im::::m   m::::m   m::::m e::::::::eeeeeeee   z::::::::::::::z     M::::::M               M::::::Ma:::::aaaa::::::a c:::::::::::::::::ch:::::h     h:::::hi::::::i n::::n    n::::n e::::::::eeeeeeee      //
//    S:::::::::::::::SS l::::::li::::::im::::m   m::::m   m::::m  ee:::::::::::::e  z:::::::::::::::z     M::::::M               M::::::M a::::::::::aa:::a cc:::::::::::::::ch:::::h     h:::::hi::::::i n::::n    n::::n  ee:::::::::::::e      //
//     SSSSSSSSSSSSSSS   lllllllliiiiiiiimmmmmm   mmmmmm   mmmmmm    eeeeeeeeeeeeee  zzzzzzzzzzzzzzzzz     MMMMMMMM               MMMMMMMM  aaaaaaaaaa  aaaa   cccccccccccccccchhhhhhh     hhhhhhhiiiiiiii nnnnnn    nnnnnn    eeeeeeeeeeeeee      //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Slimez Machine", "SM") {}
}
