
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arcane
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                            ...'',;;:::c:cccccc:::;;,''...                                            //
//                                    .,:loxkO0KXNNNNXXXXKKKKKKKKXXXXNNNNXXK0kxol:,..                                   //
//                                .cd0XNXKOxdoc:;;,''................'',,;:cldxO0XNX0xc.                                //
//                               cXN0dc,..                                      ..,:oONXl.                              //
//                              .kMKc.          .,.                    ..           .:0MO.                              //
//                               'xXNKkoc;'...'od;                     'd:.  ..';cokKNXx,                               //
//                                 .;lxOKNNXK0NW0dollccc::::::::::ccclldXW0O0KXNNKOxo:.                                 //
//                                      ..:0WW0dxkOO00KKKXXXXXXXXKKK00OO0WMMNx:,'.                                      //
//                                       .xNM0'      ................   '0MMWO'                                         //
//                                      'OWMNc                          .xMMMMO.                                        //
//                                     'OMMMO.                           oMMMMWd                                        //
//                                    .OMMMMd                            lWMMMMX;                                       //
//                                   .dWMMMMd                            oMMMMMMx.                                      //
//                                   :NMMMMMk.                          .xMMMMMMK,                                      //
//                                  .xMMMMMMX:       ..,;:ccc:'         .OMMMMMMWl                                      //
//                                  '0MMMMMMM0,  .cdkKXWMMMMMMNx;       cXMMMMMMMd                                      //
//                                  ,KMMMMMMMMK:.;XMMMMMMMMMMMMMNk;   ,kNMMMMMMMMo                                      //
//                                  .OMMMMMMMMMWOo0MMMMMMMMMMMMMMMNk' lWMMMMMMMMK,                                      //
//                                  .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'c0WMMMMW0;                                       //
//                                   lWMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMWk..,clol;.                                        //
//                                   cNMMMMMMMMMMMMMMMMMMMW0xdOWMMMMMMM0'                                               //
//                                  .OMMMMMMMMMMMMMMMMMMMXxl:;cxXMMMMMMM0'                                              //
//                                 .dWMMMMMMMMMMMMMMMMMMM0lllckXNMMMMMMMMO. ''                                          //
//                                 :NMMMMMMMKkXMMMMMMMMMMWKo;,cxKMMMMMMMMWkldx;                                         //
//                                .OMMMMMMMNc 'dKWMMMMMMMXK0dlkodMMMMMMMMXx, ;x'                                        //
//                                :NMMMMMMMk.   .cONMMMMMXxl:;lxKMMMMMW0l.    ol                                        //
//                                oWMMMMMMWl   'o:.'lkXMMMMXkx0WMMMNOo,.;o,   cd.                                       //
//                                dMMMMMMMWc  .xMX;   'kMMMMWWWMMM0;   ,KMO.  :x.                                       //
//                                oMMMMMMMMo  .dWK,   .OMMMMMMMMMMK,   .OMk.  cd.                                       //
//                                :NMMMMMMM0'  .;'   .dWMMMMMMMMMMMk.   .;.  .dc                                        //
//                                '0MMMMMMMWx. .l'  'kWMMMMMMMMMMMMWO,  .l' .oo.                                        //
//                                 lNMMMMMMMWKolollkXMMMMMMMMMMMMMMMMNOllolcl:.                                         //
//                                 .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.                                           //
//                                  .kWMMMMMMMMMMMMWNWMMMMMMMMMMMMMMWNWMMWd.                                            //
//                                   .xWMMMMMMMMMMMNd;okXNWWWWWWNXOo:oXMMO.                                             //
//                                    .cKMMMMMMMMMMM0, .;loddddol:. .OMMK,                                              //
//                                      .dXMMMMMMMMMM0,            'OWM0,                                               //
//                                        'oKWMMMMMMMMKc..      ..:0MWO'                                                //
//                                          .:xKWMMMMMMW0d:....;d0NMNo.                                                 //
//                                             .;lkKNWMMMWX0OO0XWMWk,                                                   //
//                                                 .';clodxkkkkxdo:.                                                    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARCANE is ERC721Creator {
    constructor() ERC721Creator("Arcane", "ARCANE") {}
}
