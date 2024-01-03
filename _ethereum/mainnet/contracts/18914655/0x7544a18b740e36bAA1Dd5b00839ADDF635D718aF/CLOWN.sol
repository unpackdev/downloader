// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clowncar Willie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                              .';::::,'.                    //
//                                                                           'lkKNWMMMMWN0d:.                 //
//                                                                         'xNMMMMMMMMMMMMMW0c.               //
//                                                                        :KMMMMMMMMMMMMMMMMMWk.              //
//                                                                       ;KMMMMMMMMMMMMMMMMMMMWk.             //
//                                                                      .xMMMMMMMMMMMMMMMMMMMMMWk.            //
//                                                                      .OMMMMMMMMMMMMMMMMMMMMMMWl            //
//                                                                      .kMMMMMMMNkdkKWMMMMMMMMMMx.           //
//                                                                       cNMMMWOl'   .;dKWMMMMMMMx.           //
//                                                                       .lNNx;.        .oXMMMMMMo            //
//                                                                        .:'             'OWMMMNl            //
//                                                                      .''.               .kWMMMXOc.         //
//                                                  .,coodxxxdol:'.   ... ....              '0MMMMMWO'        //
//                                               'oOXWMMMMMMMMMMMNKd,.      ..               lWMMMMMMd        //
//                                        ..   'xNMMMMMMMMMMMMMMMNk;.     ...               ;OWMMMMMMx.       //
//                                   ..   ....;OMMMMMMMMMMMMMMMNk;     ....              .;kNMMMMMMMWl        //
//                                  ..         'lONMMMMMMMMMMNOc'.......               .:OWMMMMMMMMNd.        //
//                                  ..            ,dKWMMMMMWO;    .                   .lKWMMMMMMWXk;          //
//                                   ..             .lKWMW0c.                       ... .;loddoc;.            //
//                                    ..              .lxd'                       ..                          //
//                                      ..   .';:cllc:;,,;:;,'.                 ...   .....                   //
//                                       ...'kKkoc;'..    ..';lddc,.          ....,lxO0KKKK0kdl;.             //
//                                         .,;.                'kWN0d;.     ...,dKWMMMMMMMMMMMMWKd'           //
//        .,cllc;.                 ..,.    ..;;.                .OMMMW0o'  ...oNMMMMMMMMMMMMMMMMMMNd.         //
//       .lxddddxdc.             ..:dl.   .:xx'                  lWMMMMMXx:..oWMMMMMMMMMMMMMMMMMMMMW0,        //
//       ;xdddddddxo'          ..,:;..  .coc;.                   lWMMMMMMMXllXMMMMMMMMMMMMMMMMMMMMMMMK;       //
//       'dxdddddddxo,       ..,xNN:  'xXWMO.                   .xMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMk.      //
//        ,dxddddddddd;. .....;KMWx. cXMMMWl                    :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;      //
//         .cdxddddddxd,   ..'kWWk. cNMMMWx.                   ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;      //
//           .;ldxxddxx;      .:l' '0MMMNd.                   ;KWNNXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,      //
//              'lcclc,.         . ,KMW0:                   .:lc;'.....,:dKWMMMMMMMMMMMMMMMMMMMMMMMMMWd       //
//              .'.                 'c;.                 ..... ..''.      .cKMMMMMMMMMMMMMMMMMMMMMMMWk.       //
//               ..                                   ....  .;ldxxxdo:.     'kWMMMMMMMMMMMMMMMMMMMMNd.        //
//                ..                                       'dxdxdddddxc      .OWNXWMMMMMMMMMMMMMMNk,          //
//                 ...                                     ,dkOkdddxxo,       ;Kd.:xKWMMMMMMMWXOl'            //
//                   ....                                 .:0WKoclc:'.        .xc   .,:cllolc;.               //
//                      .....                        .'cld0NMWo.              .l,                             //
//                         .....'....      ....,;clox0NMMMMMW0d,              ';.                             //
//                             .l::d;......l0KOdl:,'',:ldx0KO:.              .'.                              //
//                             .;'co.      ,o;.          .:c'               ...                               //
//                             ';.lo.                 .,:c;.               ..                                 //
//                             .:.:d'               .;c;,'              ....                                  //
//                              ;;'cl'           .,;;;'...           .....                                    //
//                               ,:;;;::;,,'',,;;:c;...       ...'''',.                                       //
//                                .''',:cccc:::,..;;'''''''''''''..                                           //
//                                    .........                                                               //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLOWN is ERC721Creator {
    constructor() ERC721Creator("Clowncar Willie", "CLOWN") {}
}
