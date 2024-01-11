
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZKX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                            ...',;.      .;,'...                                            //
//                                      .,:oxk0KNNWWl      cWWNNX0kxoc,.                                      //
//                                 .,cdOXWMMMMMMMMMWl      lWMMMMMMMMMWXOdc,.                                 //
//                              .cxKWMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMWKxc.                              //
//                           .ckXMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMXkc.                           //
//                        .;xXMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMMMWXx,                         //
//                      .:ONMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMMMMWO,                         //
//                    .:OWMMMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMMWO;.                          //
//                   ,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMWO;.     .:d,                   //
//                 .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMWO;      .:OWMNo.                 //
//                 'llllllllllllllllllllllllllllllll.      lWMMMMMMMMMMMMMWO:.     .:OWMMMMWO'                //
//                                                         lWMMMMMMMMMMMWO:.     .:OWMMMMMMMMK;               //
//                                                         lWMMMMMMMMMWO:.     .:OWMMMMMMMMMMMX:              //
//             'ccccccccccccccccccccccccccccccc'           lWMMMMMMMWO:.     .:OWMMMMMMMMMMMMMMX:             //
//            ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.           lWMMMMMWO:.     .:OWMMMMMMMMMMMMMMMMMK,            //
//           .kMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.             lWMMMWO:.     .:OWMMMMMMMMMMMMMMMMMMMMk.           //
//           lNMMMMMMMMMMMMMMMMMMMMMMMMMWO:.      ;k:      lWMWO:.     .:OWMNNWMMMMMMMMMMMMWNNWMMNl           //
//          '0MMMMMMMMMMMMMMMMMMMMMMMMWO:.      ;kNWl      lNO:.     .:OWMKl'.,lKWMMMMMMMNx:'';kWM0'          //
//          cNMMMMMMMMMMMMMMMMMMMMMMW0:.      ;kNMMWl      ';.     .:OWMMWl     .lKWMMMNx,     '0MNc          //
//         .xMMMMMMMMMMMMMMMMMMMMMW0:.      ;kNMMMMWl            .:OWMMMMMO;      .lKNx,      .dNMMx.         //
//         .OMMMMMMMMMMMMMMMMMMMW0:.      ;kNMMMMMMWl          .:OWMMMMMMMMNx,      ..      .lKWMMMO.         //
//         ,KMMMMMMMMMMMMMMMMMW0:.      ;kNMMMMMMMMWl        .;OWMMMMMMMMMMMMNx,          .lKWMMMMMK,         //
//         ,KMMMMMMMMMMMMMMMW0:.      ;kNMMMMMMMMMMWl        cXMMMMMMMMMMMMMMMMK;        .dWMMMMMMMK,         //
//         ,KMMMMMMMMMMMMMW0c.      ;kNMMMMMMMMMMMMWl        .:OWMMMMMMMMMMMMNx,          .lKWMMMMMK,         //
//         .OMMMMMMMMMMMW0c.      ;kNMMMMMMMMMMMMMMWl          .:OWMMMMMMMMNx,      ..      .lKWMMMO.         //
//         .xMMMMMMMMMW0c.      ;kNMMMMMMMMMMMMMMMMWl            .:OWMMMMM0;      .lKXx,      .dNMMx.         //
//          cNMMMMMMW0c.      ;kNMMMMMMMMMMMMMMMMMMWl      ';.     .:OWMMWo     .l0WMMMNx,     '0MWc          //
//          '0MMMMW0c.      ;kNMMMMMMMMMMMMMMMMMMMMWl      lNO:.     .:OWMKl'.'l0WMMMMMMMNx;..;kWM0'          //
//           lWMW0c.      ;kNMMMMMMMMMMMMMMMMMMMMMMWl      lWMWO;      .:OWWNXWMMMMMMMMMMMMWNNWMMNl           //
//           .x0c.      ;kNMMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMWO;      .:OWMMMMMMMMMMMMMMMMMMMMk.           //
//            ..      ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMWO;      .:OWMMMMMMMMMMMMMMMMMK,            //
//                   .:llllllllllllllllllllllllllllc.      lWMMMMMMMNk;.     .:OWMMMMMMMMMMMMMMX:             //
//                                                         lWMMMMMMMMMWO;.     .:OWMMMMMMMMMMMXc              //
//                                                         lWMMMMMMMMMMMWO;      .:OWMMMMMMMMK:               //
//                 'cllllllllllllllllllllllllllllllc.      cWMMMMMMMMMMMMMNk;      .:OWMMMMWO,                //
//                 .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl      cWMMMMMMMMMMMMMMMNk;      .:OWMNo.                 //
//                   ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMWl      cWMMMMMMMMMMMMMMMMMNk;      .cd;                   //
//                    .:0WMMMMMMMMMMMMMMMMMMMMMMMMMWl      cWMMMMMMMMMMMMMMMMMMMNk;                           //
//                      .cOWMMMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMMMMNk,                         //
//                        .;xXMMMMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMMMMXx,                         //
//                           .ckNMMMMMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMMMMMNkl.                           //
//                              .cxKWMMMMMMMMMMMMMMWl      lWMMMMMMMMMMMMMMWKxc'                              //
//                                 .,cx0XWMMMMMMMMMWl      cWMMMMMMMMMWX0xc,.                                 //
//                                      .,coxO0XNWWWl      cWMWNX0Oxoc,.                                      //
//                                            ..'';;.      .;;'...                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZKX is ERC721Creator {
    constructor() ERC721Creator("ZKX", "ZKX") {}
}
