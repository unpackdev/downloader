
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: geniuscorp
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                ..°°*ooOOOOOOOooooo**°..                                //
//                            °*oOOOOooOOOOOOOOOOoooOOOOOOOo*°                            //
//                        .°oOOOOOOOOooOOOOOOOOOOOooOOOOOOOOOOOo*.                        //
//                     .*oooOOOOOOOOOOOOOOOOOOOOOoooOOOOoooOOOOOOoo*.                     //
//                   .oOOOOooOOOOOOOOOOOOOOOOOOOoooOOOOOOoooooooooOOO*.                   //
//                 .oOOOOOOoooOOOOOOOOOOOOOOOOOooooOOOOOOOOOOoOOOOOOOoo*.                 //
//                *OOOOOOOOOooOOOOOOOoOOOOOoooooooooooooooOOOOOOOOOOOooOO*                //
//               oOOOOOOOOOOooOOOOOOOOoooooooOOOOOOOOOOOOOoooOOOOOOOOOOOO#o.              //
//             .oOOOOOOOOOOOooOOOO*°*oOOoooOOOOOOOOOOOo***OOoooOOOOOOOOOOooo.             //
//            .OOOOOOOOOOOOOooOOO.    .OOooOOOOOOOOOO°    .OOooOOOOOOOOOoooOO.            //
//            OOOOOOOOOOOOOoooOO°      .ooooooOOOOOO°      .OOOOOOOOOOOoooOOOO            //
//           *OOOOOOOOOOOOOOOOOO        °ooOOoooooOo        oOOOOOOOOOOoooOOOO*           //
//           OOOOOOOOOOOOOOOOOOO.       .OOOOOOOOoo°        oOOOOOOOOOOoooOOOOO           //
//          °OOOOOOOOOOOOOOOOOOO*       °OOOOOOOOOO*       .OOOOOOOOOOOooooooOO°          //
//          °OOOOOOOooooOOOOOOOOO°      oOOOOOOOOOOO.      oOOOOOOOOOooooOOOooo°          //
//          °OOoooooooOOOOOOOOOOOO*.  .oOOOOOOOOOOOOO°   °oOOOOOOOOOoooOOOOOOOO°          //
//          .oooOoooOOOOOOOOOOOOOO#OooOOOOOOOOOOOOOOOOoooOooooOOOOOoooOOOOOOOOO°          //
//           OOOOOoooOOOOOOOOOOOOOOoooOOOOOOOOOOOOOOOoooOOOOooooooooooOOOOOOOOO           //
//           *OOOOOooooOOOOOOOOOoooooOOOOOOOOOOOOOOOOoooOOOOOOOOOOOooooOOOOOOO*           //
//            OOOOOOOoooooooooooooOOOOOOOOOOOOOOOOOOoooOOOOOOOOOOOOOOoooOOOOOO            //
//            .OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoooOOOO.            //
//             .OOOOOOOOOOOOOOOOOOOOOOOOOOOoooOOOOOOOOOOOOOOoooOOOOOOOoooOOO.             //
//              .OOoooooOOOOOOOOOOOOOOOOOOOOOoooooOOOOOOOOOoooOOOOOOOOoooOO.              //
//                °oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoooOOOOOOOoooOOOOOOOOooO*                //
//                 .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoooOOOOOoooOOOOOOOOOo.                 //
//                   .oOOOOooooooooooooOOOOOOOOOOOOOoooOOOOOoooOOOOOOo.                   //
//                     .*oooOOOOOOOOOOooooOOOOOOOOOOOoooOOOOOooooOo*.                     //
//                        .°oOOOOOOOOOOOOoooOOOOOOOOOoooOOOOOOOo°.                        //
//                            °*oOOOOOOOOOooOOOOOOOOOOooOOOo*°                            //
//                                ..°**oooooOOOOOOOoo*°°..                                //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ    //
//    ²Û²±°°  °°±²Û²±°°  °°±²Û²±°°  °°±²Û²±°°  °°±²Û²±°°  °°±²Û²±°°  °°±²Û²±°°  °°±²Û²    //
//    ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß    //
//    $&&&                                                                        $&&&    //
//    $&&&                               geniuscorp                               $&&&    //
//    $&&&                                                                        $&&&    //
//    ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ    //
//    ²Û²±°°  °°±²Û²±°°  °°±²Û  we make records and open doors °±°°  °°±²Û²±°°  °°±²Û²    //
//    ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß    //
//    $&&&                                                                        &&&$    //
//    $&&&  CHAiN...: ETHEREUM Mainnet                                            &&&$    //
//    $&&&  TYPE....: ERC-721                                                     &&&$    //
//    $&&&  TiCKR...: GCORP                                                       &&&$    //
//    $&&&  WEBSiTE.: https://geniuscorp.fr                                       &&&$    //
//    $&&&                                                                        &&&$    //
//    $&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract gcorp is ERC721Creator {
    constructor() ERC721Creator("geniuscorp", "gcorp") {}
}
