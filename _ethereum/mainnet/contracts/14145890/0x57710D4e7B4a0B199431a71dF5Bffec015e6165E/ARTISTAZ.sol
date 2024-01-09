
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artistaz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                   AAA                                            tttt            iiii                            tttt                                                 //
//                  A:::A                                        ttt:::t           i::::i                        ttt:::t                                                 //
//                 A:::::A                                       t:::::t            iiii                         t:::::t                                                 //
//                A:::::::A                                      t:::::t                                         t:::::t                                                 //
//               A:::::::::A           rrrrr   rrrrrrrrr   ttttttt:::::ttttttt    iiiiiii     ssssssssss   ttttttt:::::ttttttt      aaaaaaaaaaaaa   zzzzzzzzzzzzzzzzz    //
//              A:::::A:::::A          r::::rrr:::::::::r  t:::::::::::::::::t    i:::::i   ss::::::::::s  t:::::::::::::::::t      a::::::::::::a  z:::::::::::::::z    //
//             A:::::A A:::::A         r:::::::::::::::::r t:::::::::::::::::t     i::::i ss:::::::::::::s t:::::::::::::::::t      aaaaaaaaa:::::a z::::::::::::::z     //
//            A:::::A   A:::::A        rr::::::rrrrr::::::rtttttt:::::::tttttt     i::::i s::::::ssss:::::stttttt:::::::tttttt               a::::a zzzzzzzz::::::z      //
//           A:::::A     A:::::A        r:::::r     r:::::r      t:::::t           i::::i  s:::::s  ssssss       t:::::t              aaaaaaa:::::a       z::::::z       //
//          A:::::AAAAAAAAA:::::A       r:::::r     rrrrrrr      t:::::t           i::::i    s::::::s            t:::::t            aa::::::::::::a      z::::::z        //
//         A:::::::::::::::::::::A      r:::::r                  t:::::t           i::::i       s::::::s         t:::::t           a::::aaaa::::::a     z::::::z         //
//        A:::::AAAAAAAAAAAAA:::::A     r:::::r                  t:::::t    tttttt i::::i ssssss   s:::::s       t:::::t    tttttta::::a    a:::::a    z::::::z          //
//       A:::::A             A:::::A    r:::::r                  t::::::tttt:::::ti::::::is:::::ssss::::::s      t::::::tttt:::::ta::::a    a:::::a   z::::::zzzzzzzz    //
//      A:::::A               A:::::A   r:::::r                  tt::::::::::::::ti::::::is::::::::::::::s       tt::::::::::::::ta:::::aaaa::::::a  z::::::::::::::z    //
//     A:::::A                 A:::::A  r:::::r                    tt:::::::::::tti::::::i s:::::::::::ss          tt:::::::::::tt a::::::::::aa:::az:::::::::::::::z    //
//    AAAAAAA                   AAAAAAA rrrrrrr                      ttttttttttt  iiiiiiii  sssssssssss              ttttttttttt    aaaaaaaaaa  aaaazzzzzzzzzzzzzzzzz    //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTISTAZ is ERC721Creator {
    constructor() ERC721Creator("Artistaz", "ARTISTAZ") {}
}
