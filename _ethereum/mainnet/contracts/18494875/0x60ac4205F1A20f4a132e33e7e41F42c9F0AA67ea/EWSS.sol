// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EvaWeiss
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//    EEEEEEEEEEEEEEEEEEEEEE                                  WWWWWWWW                           WWWWWWWW               iiii                                      //
//    E::::::::::::::::::::E                                  W::::::W                           W::::::W              i::::i                                     //
//    E::::::::::::::::::::E                                  W::::::W                           W::::::W               iiii                                      //
//    EE::::::EEEEEEEEE::::E                                  W::::::W                           W::::::W                                                         //
//      E:::::E       EEEEEvvvvvvv           vvvvvvaaaaaaaaaaaaW:::::W           WWWWW           W:::::Weeeeeeeeeeee  iiiiiii    ssssssssss      ssssssssss       //
//      E:::::E             v:::::v         v:::::va::::::::::::W:::::W         W:::::W         W:::::ee::::::::::::eei:::::i  ss::::::::::s   ss::::::::::s      //
//      E::::::EEEEEEEEEE    v:::::v       v:::::v aaaaaaaaa:::::W:::::W       W:::::::W       W:::::e::::::eeeee:::::ei::::iss:::::::::::::sss:::::::::::::s     //
//      E:::::::::::::::E     v:::::v     v:::::v           a::::aW:::::W     W:::::::::W     W:::::e::::::e     e:::::i::::is::::::ssss:::::s::::::ssss:::::s    //
//      E:::::::::::::::E      v:::::v   v:::::v     aaaaaaa:::::a W:::::W   W:::::W:::::W   W:::::We:::::::eeeee::::::i::::i s:::::s  ssssss s:::::s  ssssss     //
//      E::::::EEEEEEEEEE       v:::::v v:::::v    aa::::::::::::a  W:::::W W:::::W W:::::W W:::::W e:::::::::::::::::ei::::i   s::::::s        s::::::s          //
//      E:::::E                  v:::::v:::::v    a::::aaaa::::::a   W:::::W:::::W   W:::::W:::::W  e::::::eeeeeeeeeee i::::i      s::::::s        s::::::s       //
//      E:::::E       EEEEEE      v:::::::::v    a::::a    a:::::a    W:::::::::W     W:::::::::W   e:::::::e          i::::issssss   s:::::sssssss   s:::::s     //
//    EE::::::EEEEEEEE:::::E       v:::::::v     a::::a    a:::::a     W:::::::W       W:::::::W    e::::::::e        i::::::s:::::ssss::::::s:::::ssss::::::s    //
//    E::::::::::::::::::::E        v:::::v      a:::::aaaa::::::a      W:::::W         W:::::W      e::::::::eeeeeeeei::::::s::::::::::::::ss::::::::::::::s     //
//    E::::::::::::::::::::E         v:::v        a::::::::::aa:::a      W:::W           W:::W        ee:::::::::::::ei::::::is:::::::::::ss  s:::::::::::ss      //
//    EEEEEEEEEEEEEEEEEEEEEE          vvv          aaaaaaaaaa  aaaa       WWW             WWW           eeeeeeeeeeeeeeiiiiiiii sssssssssss     sssssssssss        //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EWSS is ERC1155Creator {
    constructor() ERC1155Creator("EvaWeiss", "EWSS") {}
}
