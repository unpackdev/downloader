
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JVEmedia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                        dddddddd                              //
//                 jjjj                                                                                                   d::::::d  iiii                        //
//                j::::j                                                                                                  d::::::d i::::i                       //
//                 jjjj                                                                                                   d::::::d  iiii                        //
//                                                                                                                        d:::::d                               //
//               jjjjjjjvvvvvvv           vvvvvvv eeeeeeeeeeee       mmmmmmm    mmmmmmm       eeeeeeeeeeee        ddddddddd:::::d iiiiiii   aaaaaaaaaaaaa       //
//               j:::::j v:::::v         v:::::vee::::::::::::ee   mm:::::::m  m:::::::mm   ee::::::::::::ee    dd::::::::::::::d i:::::i   a::::::::::::a      //
//                j::::j  v:::::v       v:::::ve::::::eeeee:::::eem::::::::::mm::::::::::m e::::::eeeee:::::ee d::::::::::::::::d  i::::i   aaaaaaaaa:::::a     //
//                j::::j   v:::::v     v:::::ve::::::e     e:::::em::::::::::::::::::::::me::::::e     e:::::ed:::::::ddddd:::::d  i::::i            a::::a     //
//                j::::j    v:::::v   v:::::v e:::::::eeeee::::::em:::::mmm::::::mmm:::::me:::::::eeeee::::::ed::::::d    d:::::d  i::::i     aaaaaaa:::::a     //
//                j::::j     v:::::v v:::::v  e:::::::::::::::::e m::::m   m::::m   m::::me:::::::::::::::::e d:::::d     d:::::d  i::::i   aa::::::::::::a     //
//                j::::j      v:::::v:::::v   e::::::eeeeeeeeeee  m::::m   m::::m   m::::me::::::eeeeeeeeeee  d:::::d     d:::::d  i::::i  a::::aaaa::::::a     //
//                j::::j       v:::::::::v    e:::::::e           m::::m   m::::m   m::::me:::::::e           d:::::d     d:::::d  i::::i a::::a    a:::::a     //
//                j::::j        v:::::::v     e::::::::e          m::::m   m::::m   m::::me::::::::e          d::::::ddddd::::::ddi::::::ia::::a    a:::::a     //
//                j::::j         v:::::v       e::::::::eeeeeeee  m::::m   m::::m   m::::m e::::::::eeeeeeee   d:::::::::::::::::di::::::ia:::::aaaa::::::a     //
//                j::::j          v:::v         ee:::::::::::::e  m::::m   m::::m   m::::m  ee:::::::::::::e    d:::::::::ddd::::di::::::i a::::::::::aa:::a    //
//                j::::j           vvv            eeeeeeeeeeeeee  mmmmmm   mmmmmm   mmmmmm    eeeeeeeeeeeeee     ddddddddd   dddddiiiiiiii  aaaaaaaaaa  aaaa    //
//                j::::j                                                                                                                                        //
//      jjjj      j::::j                                                                                                                                        //
//     j::::jj   j:::::j                                                                                                                                        //
//     j::::::jjj::::::j                                                                                                                                        //
//      jj::::::::::::j                                                                                                                                         //
//        jjj::::::jjj                                                                                                                                          //
//           jjjjjj                                                                                                                                             //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JVE is ERC721Creator {
    constructor() ERC721Creator("JVEmedia", "JVE") {}
}
