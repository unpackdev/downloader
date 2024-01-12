
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI Art By Reaper
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                             //
//                   AAA                                           tttt               BBBBBBBBBBBBBBBBB                                 RRRRRRRRRRRRRRRRR                                                                                                      //
//                  A:::A                                       ttt:::t               B::::::::::::::::B                                R::::::::::::::::R                                                                                                     //
//                 A:::::A                                      t:::::t               B::::::BBBBBB:::::B                               R::::::RRRRRR:::::R                                                                                                    //
//                A:::::::A                                     t:::::t               BB:::::B     B:::::B                              RR:::::R     R:::::R                                                                                                   //
//               A:::::::::A          rrrrr   rrrrrrrrr   ttttttt:::::ttttttt           B::::B     B:::::Byyyyyyy           yyyyyyy       R::::R     R:::::R    eeeeeeeeeeee    aaaaaaaaaaaaa  ppppp   ppppppppp       eeeeeeeeeeee    rrrrr   rrrrrrrrr       //
//              A:::::A:::::A         r::::rrr:::::::::r  t:::::::::::::::::t           B::::B     B:::::B y:::::y         y:::::y        R::::R     R:::::R  ee::::::::::::ee  a::::::::::::a p::::ppp:::::::::p    ee::::::::::::ee  r::::rrr:::::::::r      //
//             A:::::A A:::::A        r:::::::::::::::::r t:::::::::::::::::t           B::::BBBBBB:::::B   y:::::y       y:::::y         R::::RRRRRR:::::R  e::::::eeeee:::::eeaaaaaaaaa:::::ap:::::::::::::::::p  e::::::eeeee:::::eer:::::::::::::::::r     //
//            A:::::A   A:::::A       rr::::::rrrrr::::::rtttttt:::::::tttttt           B:::::::::::::BB     y:::::y     y:::::y          R:::::::::::::RR  e::::::e     e:::::e         a::::app::::::ppppp::::::pe::::::e     e:::::err::::::rrrrr::::::r    //
//           A:::::A     A:::::A       r:::::r     r:::::r      t:::::t                 B::::BBBBBB:::::B     y:::::y   y:::::y           R::::RRRRRR:::::R e:::::::eeeee::::::e  aaaaaaa:::::a p:::::p     p:::::pe:::::::eeeee::::::e r:::::r     r:::::r    //
//          A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr      t:::::t                 B::::B     B:::::B     y:::::y y:::::y            R::::R     R:::::Re:::::::::::::::::e aa::::::::::::a p:::::p     p:::::pe:::::::::::::::::e  r:::::r     rrrrrrr    //
//         A:::::::::::::::::::::A     r:::::r                  t:::::t                 B::::B     B:::::B      y:::::y:::::y             R::::R     R:::::Re::::::eeeeeeeeeee a::::aaaa::::::a p:::::p     p:::::pe::::::eeeeeeeeeee   r:::::r                //
//        A:::::AAAAAAAAAAAAA:::::A    r:::::r                  t:::::t    tttttt       B::::B     B:::::B       y:::::::::y              R::::R     R:::::Re:::::::e         a::::a    a:::::a p:::::p    p::::::pe:::::::e            r:::::r                //
//       A:::::A             A:::::A   r:::::r                  t::::::tttt:::::t     BB:::::BBBBBB::::::B        y:::::::y             RR:::::R     R:::::Re::::::::e        a::::a    a:::::a p:::::ppppp:::::::pe::::::::e           r:::::r                //
//      A:::::A               A:::::A  r:::::r                  tt::::::::::::::t     B:::::::::::::::::B          y:::::y              R::::::R     R:::::R e::::::::eeeeeeeea:::::aaaa::::::a p::::::::::::::::p  e::::::::eeeeeeee   r:::::r                //
//     A:::::A                 A:::::A r:::::r                    tt:::::::::::tt     B::::::::::::::::B          y:::::y               R::::::R     R:::::R  ee:::::::::::::e a::::::::::aa:::ap::::::::::::::pp    ee:::::::::::::e   r:::::r                //
//    AAAAAAA                   AAAAAAArrrrrrr                      ttttttttttt       BBBBBBBBBBBBBBBBB          y:::::y                RRRRRRRR     RRRRRRR    eeeeeeeeeeeeee  aaaaaaaaaa  aaaap::::::pppppppp        eeeeeeeeeeeeee   rrrrrrr                //
//                                                                                                              y:::::y                                                                         p:::::p                                                        //
//                                                                                                             y:::::y                                                                          p:::::p                                                        //
//                                                                                                            y:::::y                                                                          p:::::::p                                                       //
//                                                                                                           y:::::y                                                                           p:::::::p                                                       //
//                                                                                                          yyyyyyy                                                                            p:::::::p                                                       //
//                                                                                                                                                                                             ppppppppp                                                       //
//                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ABR is ERC721Creator {
    constructor() ERC721Creator("AI Art By Reaper", "ABR") {}
}
