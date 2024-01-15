
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PBXDESIGN Personal Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    Copyright (C) Donavan Lewis - All Rights Reserved                                                                           //
//                                                                                                                                //
//    Unauthorized copying of this file, contract, collection, images or logos within this collection, text in this file          //
//    or within this collection, 3d models, audio files or other content contained within this collection, via any medium         //
//    is strictly prohibited.                                                                                                     //
//                                                                                                                                //
//    Proprietary                                                                                                                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                   ........................          ........................                                   //
//                                   .'lkKXXXXXXXXXXXXKXXXKKx,.      .,xKKXXXKXXXXXXXXXXXXKkl'.                                   //
//                                     .,xWMMMMMMMMMMMMMMMMMWXd'.  .'dXWMMMMMMMMMMMMMMMMMWx,.                                     //
//                                      .lNMMMMMMMMMMMMMMMMMMMWk'  'kWMMMMMMMMMMMMMMMMMMMNl                                       //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .cKNNNNNNNNNNWMMMMMMMMMO'  'OMMMMMMMMMWNNNNNNNNNNKc.                                      //
//                                       .,,,,,,,,,,,:kNMMMMMMMO'  'OMMMMMMMNk:,,,,,,,,,,,.                                       //
//                                                    .lKWMMMMMO'  'OMMMMMWKl.                                                    //
//                      ..''''''''''''''''''''''..     .,kNMMMMO'  'OMMMMNk,.     ..''''''''''''''''''''''..                      //
//                      .,xKXXXNNNXXXXXXXXXXXXXX0l.      .lKWMMO,  ,OMMWKl.      .l0XXXXXXXXXXXXXXXXXXXXXx;.                      //
//                        'oXMMMMMMMMMMMMMMMMMMMMWO;.     .,xNMO'  'OMNx,.     .;OWMMMMMMMMMMMMMMMMMMMMXo'                        //
//                         .;kNMMMMMMMMMMMMMMMMMMMMXo'      .c0O,  ,O0c.      .oXMMMMMMMMMMMMMMMMMMMMNk;.                         //
//                           .c0WMMMMMMMMMMMMMMMMMMMW0:.     .,:.  .:,.     .:0WMMMMMMMMMMMMMMMMMMMW0c.                           //
//                             'dXMMMMMMMMMMMMMMMMMMMMNx'.                .'dNMMMMMMMMMMMMMMMMMMMMXd'                             //
//                              .;kNMMMMMMMMMMMMMMMMMMMW0c.              .c0WMMMMMMMMMMMMMMMMMMMNk;.                              //
//                                .c0WMMMMMMMMMMMMMMMMMMMNk,.          .,kNMMMMMMMMMMMMMMMMMMMW0l.                                //
//                                 .'dXMMMMMMMMMMMMMMMMMMMWKl.        .lKWMMMMMMMMMMMMMMMMMMMXd'.                                 //
//                                   .;ONMMMMMMMMMMMMMMMMMMMWO;.    .;OWMMMMMMMMMMMMMMMMMMMNO;.                                   //
//                                     .lKWMMMMMMMMMMMMMMMMMMMXo'...oXMMMMMMMMMMMMMMMMMMMWKl.                                     //
//                                      .cXMMMMMMMMMMMMMMMMMMMMWkllkWMMMMMMMMMMMMMMMMMMMMXc.                                      //
//                                     .:0WMMMMMMMMMMMMMMMMMMMWKl,'lKWMMMMMMMMMMMMMMMMMMMW0:.                                     //
//                                    .dXMMMMMMMMMMMMMMMMMMMMNx,.  .,xNMMMMMMMMMMMMMMMMMMMMXd.                                    //
//                                  .;OWMMMMMMMMMMMMMMMMMMMW0:.      .:0WMMMMMMMMMMMMMMMMMMMWO;.                                  //
//                                 .lKMMMMMMMMMMMMMMMMMMMMXd'         .'dXMMMMMMMMMMMMMMMMMMMWKl.                                 //
//                               .'xNMMMMMMMMMMMMMMMMMMMWO:.            .;OWMMMMMMMMMMMMMMMMMMMNx,.                               //
//                              .:0WMMMMMMMMMMMMMMMMMMMKo.                .oKMMMMMMMMMMMMMMMMMMMW0:.                              //
//                             .dXMMMMMMMMMMMMMMMMMMMNk,.     ...  ...     .,kNMMMMMMMMMMMMMMMMMMMXd.                             //
//                           .;OWMMMMMMMMMMMMMMMMMMWKl.      .od'  'do.      .lKWMMMMMMMMMMMMMMMMMMWO;.                           //
//                          .lKWMMMMMMMMMMMMMMMMMMNx,.     .;OWO'  'OWO;.     .'xNMMMMMMMMMMMMMMMMMMMKl.                          //
//                         .dXNNNNNNNNNNNNNNNNNNNOc.      'dXMMO'  'OMMXd.      .:ONNNNNNNNNNNNNNNNNNNXd.                         //
//                         .,,,,,,,,,,,,,,,,,,,,,.      .:OWMMMO'  'OMMMWO:.      .,,,,,,,,,,,,,,,,,,,,,.                         //
//                                                     'dXMMMMMO'  'OMMMMMXd'                                                     //
//                                                   .:0WMMMMMMO'  'OMMMMMMW0:.                                                   //
//                                       ,oxxxxxxxxxxONMMMMMMMMO'  'OMMMMMMMMNOxxxxxxxxxxo,                                       //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMMMO'  'OMMMMMMMMMMMMMMMMMMMMNl.                                      //
//                                      .lNMMMMMMMMMMMMMMMMMMWKl.  .lKWMMMMMMMMMMMMMMMMMMNl.                                      //
//                                    .;dKWMMMMMMMMMMMMMMMMWXd,.    .,dXWMMMMMMMMMMMMMMMMWKd;.                                    //
//                                   .'coooooooooooooooooool,.        .,loooooooooooooooooooc'.                                   //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PBXnft is ERC721Creator {
    constructor() ERC721Creator("PBXDESIGN Personal Collection", "PBXnft") {}
}
