
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections By 9GreenRats
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//    RRRRRRRRRRRRRRRRR                          ffffffffffffffff  lllllll                                                  tttt            iiii                                                               //
//    R::::::::::::::::R                        f::::::::::::::::f l:::::l                                               ttt:::t           i::::i                                                              //
//    R::::::RRRRRR:::::R                      f::::::::::::::::::fl:::::l                                               t:::::t            iiii                                                               //
//    RR:::::R     R:::::R                     f::::::fffffff:::::fl:::::l                                               t:::::t                                                                               //
//      R::::R     R:::::R    eeeeeeeeeeee     f:::::f       ffffff l::::l     eeeeeeeeeeee        ccccccccccccccccttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss            //
//      R::::R     R:::::R  ee::::::::::::ee   f:::::f              l::::l   ee::::::::::::ee    cc:::::::::::::::ct:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s           //
//      R::::RRRRRR:::::R  e::::::eeeee:::::eef:::::::ffffff        l::::l  e::::::eeeee:::::ee c:::::::::::::::::ct:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s          //
//      R:::::::::::::RR  e::::::e     e:::::ef::::::::::::f        l::::l e::::::e     e:::::ec:::::::cccccc:::::ctttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s         //
//      R::::RRRRRR:::::R e:::::::eeeee::::::ef::::::::::::f        l::::l e:::::::eeeee::::::ec::::::c     ccccccc      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss          //
//      R::::R     R:::::Re:::::::::::::::::e f:::::::ffffff        l::::l e:::::::::::::::::e c:::::c                   t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s               //
//      R::::R     R:::::Re::::::eeeeeeeeeee   f:::::f              l::::l e::::::eeeeeeeeeee  c:::::c                   t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s            //
//      R::::R     R:::::Re:::::::e            f:::::f              l::::l e:::::::e           c::::::c     ccccccc      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s          //
//    RR:::::R     R:::::Re::::::::e          f:::::::f            l::::::le::::::::e          c:::::::cccccc:::::c      t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s         //
//    R::::::R     R:::::R e::::::::eeeeeeee  f:::::::f            l::::::l e::::::::eeeeeeee   c:::::::::::::::::c      tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s          //
//    R::::::R     R:::::R  ee:::::::::::::e  f:::::::f            l::::::l  ee:::::::::::::e    cc:::::::::::::::c        tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss           //
//    RRRRRRRR     RRRRRRR    eeeeeeeeeeeeee  fffffffff            llllllll    eeeeeeeeeeeeee      cccccccccccccccc          ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                    BBBBBBBBBBBBBBBBB                                                                                                        //
//                                                                                    B::::::::::::::::B                                                                                                       //
//                                                                                    B::::::BBBBBB:::::B                                                                                                      //
//                                                                                    BB:::::B     B:::::B                                                                                                     //
//                                                                                      B::::B     B:::::Byyyyyyy           yyyyyyy                                                                            //
//                                                                                      B::::B     B:::::B y:::::y         y:::::y                                                                             //
//                                                                                      B::::BBBBBB:::::B   y:::::y       y:::::y                                                                              //
//                                                                                      B:::::::::::::BB     y:::::y     y:::::y                                                                               //
//                                                                                      B::::BBBBBB:::::B     y:::::y   y:::::y                                                                                //
//                                                                                      B::::B     B:::::B     y:::::y y:::::y                                                                                 //
//                                                                                      B::::B     B:::::B      y:::::y:::::y                                                                                  //
//                                                                                      B::::B     B:::::B       y:::::::::y                                                                                   //
//                                                                                    BB:::::BBBBBB::::::B        y:::::::y                                                                                    //
//                                                                                    B:::::::::::::::::B          y:::::y                                                                                     //
//                                                                                    B::::::::::::::::B          y:::::y                                                                                      //
//                                                                                    BBBBBBBBBBBBBBBBB          y:::::y                                                                                       //
//                                                                                                              y:::::y                                                                                        //
//                                                                                                             y:::::y                                                                                         //
//                                                                                                            y:::::y                                                                                          //
//                                                                                                           y:::::y                                                                                           //
//                                                                                                          yyyyyyy                                                                                            //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//         999999999             GGGGGGGGGGGGG                                                                              RRRRRRRRRRRRRRRRR                             tttt                                 //
//       99:::::::::99        GGG::::::::::::G                                                                              R::::::::::::::::R                         ttt:::t                                 //
//     99:::::::::::::99    GG:::::::::::::::G                                                                              R::::::RRRRRR:::::R                        t:::::t                                 //
//    9::::::99999::::::9  G:::::GGGGGGGG::::G                                                                              RR:::::R     R:::::R                       t:::::t                                 //
//    9:::::9     9:::::9 G:::::G       GGGGGGrrrrr   rrrrrrrrr       eeeeeeeeeeee        eeeeeeeeeeee    nnnn  nnnnnnnn      R::::R     R:::::R  aaaaaaaaaaaaa  ttttttt:::::ttttttt        ssssssssss         //
//    9:::::9     9:::::9G:::::G              r::::rrr:::::::::r    ee::::::::::::ee    ee::::::::::::ee  n:::nn::::::::nn    R::::R     R:::::R  a::::::::::::a t:::::::::::::::::t      ss::::::::::s        //
//     9:::::99999::::::9G:::::G              r:::::::::::::::::r  e::::::eeeee:::::ee e::::::eeeee:::::een::::::::::::::nn   R::::RRRRRR:::::R   aaaaaaaaa:::::at:::::::::::::::::t    ss:::::::::::::s       //
//      99::::::::::::::9G:::::G    GGGGGGGGGGrr::::::rrrrr::::::re::::::e     e:::::ee::::::e     e:::::enn:::::::::::::::n  R:::::::::::::RR             a::::atttttt:::::::tttttt    s::::::ssss:::::s      //
//        99999::::::::9 G:::::G    G::::::::G r:::::r     r:::::re:::::::eeeee::::::ee:::::::eeeee::::::e  n:::::nnnn:::::n  R::::RRRRRR:::::R     aaaaaaa:::::a      t:::::t           s:::::s  ssssss       //
//             9::::::9  G:::::G    GGGGG::::G r:::::r     rrrrrrre:::::::::::::::::e e:::::::::::::::::e   n::::n    n::::n  R::::R     R:::::R  aa::::::::::::a      t:::::t             s::::::s            //
//            9::::::9   G:::::G        G::::G r:::::r            e::::::eeeeeeeeeee  e::::::eeeeeeeeeee    n::::n    n::::n  R::::R     R:::::R a::::aaaa::::::a      t:::::t                s::::::s         //
//           9::::::9     G:::::G       G::::G r:::::r            e:::::::e           e:::::::e             n::::n    n::::n  R::::R     R:::::Ra::::a    a:::::a      t:::::t    ttttttssssss   s:::::s       //
//          9::::::9       G:::::GGGGGGGG::::G r:::::r            e::::::::e          e::::::::e            n::::n    n::::nRR:::::R     R:::::Ra::::a    a:::::a      t::::::tttt:::::ts:::::ssss::::::s      //
//         9::::::9         GG:::::::::::::::G r:::::r             e::::::::eeeeeeee   e::::::::eeeeeeee    n::::n    n::::nR::::::R     R:::::Ra:::::aaaa::::::a      tt::::::::::::::ts::::::::::::::s       //
//        9::::::9            GGG::::::GGG:::G r:::::r              ee:::::::::::::e    ee:::::::::::::e    n::::n    n::::nR::::::R     R:::::R a::::::::::aa:::a       tt:::::::::::tt s:::::::::::ss        //
//       99999999                GGGGGG   GGGG rrrrrrr                eeeeeeeeeeeeee      eeeeeeeeeeeeee    nnnnnn    nnnnnnRRRRRRRR     RRRRRRR  aaaaaaaaaa  aaaa         ttttttttttt    sssssssssss          //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Rb9 is ERC721Creator {
    constructor() ERC721Creator("Reflections By 9GreenRats", "Rb9") {}
}
