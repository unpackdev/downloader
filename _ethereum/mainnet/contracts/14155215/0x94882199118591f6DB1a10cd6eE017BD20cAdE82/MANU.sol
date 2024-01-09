
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Msp4rrow's Manifold Contract ERC721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                         .°..                                           //
//                                         .°°°*                                          //
//                                             °*                                         //
//                                       ......°°.                                        //
//                                  .°**oooo***.°****°..                                  //
//                               .*ooooo***°.°°°°*****o**°.                               //
//                           . .*o*****°°°°°.°°***********o*°                             //
//                          .*°*°°°.°°°°°°****o*************o*.                           //
//                        °°*°°°°°°.°**oooooooooooooooo*******o*.                         //
//                       °*°°......*ooOOOOOOOOOOOOoooooooooo*****.                        //
//                       .°°°°*°°*oOOOOOOOOOOOOOOOOOOOooooooo****o°                       //
//                       *o**ooooOOOOOOOOOOOOOOOOOOOOOOOOOOoooo***o°                      //
//                      oo***ooooOOOOOOOOOOOOOOOOOOOOOOOOOOOooooo**o*                     //
//                     *o***ooOooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoooo**o° .                  //
//                    *Oo**oooOooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoo****°..                 //
//                   °Oo**oooOOo*OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoo****.°**.              //
//                   oo**oooOOOo°OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo**°*°...°°*.             //
//                  *O**ooooOOOOoOOOOOOOOOOOOOOOOOOOOOOOOOOOo*****°.°°  ....°             //
//                  oo**oooOOOOOOOOOOOOOOOOOOOOOooOOOOOoo****°*°******..*.                //
//                 °Oo*ooooOOOOOOOOOOOOOOOOOOOOOOoooo***°.**ooooooooo*°°o*                //
//                 oo*ooooOOOOOOO°oOOOOOOOOOOoooo***°°***ooOOOOOOOOOoo***o.               //
//                .Ooo**oooooOOOo.*oooo*°*oo****°°°***ooOOOOOOOOOOOOooo**o*               //
//               .***°.°*°°°**°***°°°°°°.°*°.***°*oooOoooOOOOOOOOOOOooo***o.              //
//             **°°°°°°°****o****°°°°°°°...°**ooooooooooOOOOOOOOOOOOOooo**o°              //
//             °..****oooooOOOOOo°****°...*ooooooooooooooOOOOOOOOOOOOOoo**o*              //
//              °.**oooOOoOOOOOOo*oooOO°**o****ooooooooooOOOOOOOOOOOOOooo***              //
//              °.oooooOOOOOOOOOooooOOo*oo*******oooooooooOOOOOOOOOOOOooo**o.             //
//               °oooooOOOOOOOOoOooOOOoo****°°°****ooooooooOOOOOOOOOOOOoo**o°             //
//               °oooooOOOOOOOOOOOOOOoo*******°°°***ooooooooOOOOOOOOOOOoo**o°             //
//               *oooooOOOOOOOOOOOOOooo*°***..°°°°****ooooooOOOOOOOOOOOooo°**             //
//               *o*oooOOOOOOOOOOOOOooo**o°    .°°****oooooooooOOOOOOOOoo*..*             //
//               *o*oooOOOOOOOOOOOOooo**o°       °.°°*ooo*oo**oooooOOOOoo*. °..           //
//               *o*oooOOOOOOOOOOOoooo***         .°..°°.°**..°°°°.*°*°*°°°.°°*°          //
//               *o*oooOOOOOOOOOOOoooo*o*        °*...***o*o****o*°**°°*°.....°°°         //
//               *o*oooOOOOOOOOOOOoooo*o°        °°. *ooooooOoOoooOOOOOoo*..°.  .         //
//               °o*oooOOOOOOOOOOOOooo*o*       .... *ooooOOOOOOOOoOOOOoo*.**             //
//               °o*oooOOOOOOOOOOOOooo*oo         ...*oooOOOOOOOoOOOOOOoo*°**             //
//               °o*ooooOOOOOOOOOOOOoo**o°      ..°***ooOOOOOoOooooOOOOooo°**             //
//               .o**oooooo.*oooooo***°°*°°°.°..°..*o*ooOOOOOOoOOOOOOOoooo***             //
//                ****°°°°°..°**.°*°.°... .......°*o**ooOOOOOOOOOOOOOOooo**o°             //
//               °°°.°°°°°°°°*oooOOooo*°....°°°°****o*oOOOOOOOOOOOOOOooo***o.             //
//              .*..°.°°***°°OOOOOOOOoo*°.°********ooooOOOOOOOOOOOOOOooo***o.             //
//                .o**ooOOOo*OOOOOOOOOooo°********ooooOOOOOOOOOOOOOOOooo****              //
//                 *o*ooOOOOoOOOOOOOOOooo**o*****ooooOOOOOOOOOOOOOOOooo****°              //
//                 °o*oooOOOoOOOOOOOOOOoooooooo*oooooOOOOOOOOOOOOOOOooo***o.              //
//                 .o*oooOOOoOOOOOOOOOOoooooooooooooOOOOOOOOOOOOOOOOooo****               //
//                  *o*ooOOOOOOOOOOOOOOoO**oooooooOOOOOOOOOOOOOOOOOooo****.               //
//                  °o*oooOO*oOOOOOOOOOOOooooooooOOOOOOOOOOOOOOOOOOoo**°°. ..             //
//                   oooooOO*oOOOOOOOOOOOOOooooOOOOOOOOOOOOOOoOooo**°°°.°°..°.            //
//                   °o*ooOo°°OOOOOOOOOOOooOooOOOOOOOOooo*oo**°**..°°....°....            //
//                    ooooooo°oOOOOOOOOOOOooOOOOo*o*°°°°. °°*°°oo°°*°°°. ...°°            //
//                    °o*oooOoOOOOOOOOOOOOooOooo*°......°.*OooOooo****°      .            //
//                     *oooooooOOOOOOOOOOoo***°°°...°°°...oOOOOoo****°                    //
//                     .ooooooooOOOOOOO***°°°°***.°ooOOO.°oOOooo*****.                    //
//                      °oooooooooo***°°°**oooOOo*oOOOOOooOoooo**°**.                     //
//                       °*****°°*°.°ooooOOOoOOOoOOOOOooooooo**°°**.                      //
//                      ..°°.°°.°**ooOOOOoooooOOOOOOOOoo**o***°°*°.                       //
//                    .°*°.°°°***oooooooooooooOOOOOOoooo*°**°°**°                         //
//                      °°..°*****oooooooooooooooOoooo**°°°°°**.                          //
//                       . ...oo****ooooooooooooooooo***°°***.                            //
//                         .. .*o****oooooooooooo****°*°.°*°                              //
//                              .******************°°°*...                                //
//                                .°********°°°°°°°°°°.                                   //
//                                    ..°°°°........                                      //
//                                              ...                                       //
//                                            ....                                        //
//                                          ..°.                                          //
//                                         .°° .                                          //
//                                        °°°                                             //
//                                      .°°.                                              //
//                                      .*.                                               //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MANU is ERC721Creator {
    constructor() ERC721Creator("Msp4rrow's Manifold Contract ERC721", "MANU") {}
}
