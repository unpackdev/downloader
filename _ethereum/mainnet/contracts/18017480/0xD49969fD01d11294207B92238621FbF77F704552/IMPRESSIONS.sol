// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IMPRESSIONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                         ,l;                                                                    //
//                                                         dM0:                                                                   //
//                                                        cXMM0'                                                                  //
//                                                      .cKMMMXo.                                                                 //
//                                                      '0MMMMMN:                                                                 //
//                                                     .xNMMMMMWO'                                                                //
//                                                    .xWMMMMMMMWkc'                                                              //
//                                                   .xWMMMMMMMMMMMd.                                                             //
//                                                  .xWMMMMMMMMMMMMx.                                                             //
//                                                .cONMMMMMMMMMMMMMNd.                                                            //
//                                                ,KMMMMMMMMMMMMMMMMO.                                                            //
//                                               .xNMMMMMMMMMMMMMMMMO.                                                            //
//                                              .xWMMMMMMMMMMMMMMMMMO.                                                            //
//                                              dMMMMMMMMMMMMMMMMMMMO.                                                            //
//                                              dMMMMMMMMMMMMMMMMMMWk.                                                            //
//                                              dMMMMMMMMMMMMMMMMMMO'                                                             //
//                                              lNMMMMMMMMMMMMMMXxc'                                                              //
//                                               oWMMMMMMMMMMWXx,                                                                 //
//                                               ,0WMMMMMMWKo,.                                                                   //
//                                                .l0WMW0o:.   .                                                                  //
//                                                  .cdc.   .lOk,                                                                 //
//                                                       .lxKWMX;                                                                 //
//                                                     'dKWMMMMNc                                                                 //
//                                                    ;XMMMMMMMWK;                                                                //
//                                                    .xWMMMMMMMWc                                                                //
//                                                     .xNMMMMMMWOc'                                                              //
//                                                      '0MMMMMMMMMd.                                                             //
//                                                      .:0MMMWXKxc'                                                              //
//                                                       .xMWKo'.                                                                 //
//                                                       .lOo.   .''.                                                             //
//                                                            .coONNk.                                                            //
//                                                          .l0WMMMMKc.                                                           //
//                                                          cNMMMMMMMK,                                                           //
//                                                          .xNMMMMMMK,                                                           //
//                                                           ,KMMMMMMXo.                                                          //
//                                                           .cKMMMMMMN:                                                          //
//                                                            .kWMMMMMNc                                                          //
//                                                             'OMMMMMWd.                                                         //
//                                                             .dMMMMMMMo                                                         //
//                                                              ;0MMMMMMd                                                         //
//                                                               lWMMMMMXl                                                        //
//                                                               .ckWMMMMx.                                                       //
//                                                                 :XMMMMk.                                                       //
//                                                                 ,OWMMMXo.                                                      //
//                                                                  ,0MMMM0'                                                      //
//                                                                  .dXMMM0'                                                      //
//                                                                   .kMMMNx.                                                     //
//                                                                   .xWMMMN:                                                     //
//                                                                    'kMMMNd.                                                    //
//                                                                     lNMMMWl                                                    //
//                                                                      oWMMWl                                                    //
//                                                                      cNMMWx.                                                   //
//                                                                      .xNMMWd.                                                  //
//                                                                       .dNMMx.                                                  //
//                                                                        .OMMx.                                                  //
//                                                                        .:0Nd.                                                  //
//                                                                          .'.                                                   //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IMPRESSIONS is ERC721Creator {
    constructor() ERC721Creator("IMPRESSIONS", "IMPRESSIONS") {}
}
