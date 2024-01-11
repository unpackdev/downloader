
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ILLI$T X MAXXIMILLIAN
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                     ...',;;;;;;;,'..                                                                                  //
//                                               .';;clodddddddddddolc;;'..                                              //
//                      ........               .';codddddddddddddddddddoc;'.               ........                      //
//                  ..',;;;;,.                .,clloooooodddddddddooooolloc,.                .,;;;,,'..                  //
//                 .,;;;;;,'.         .      .;looooooollooooooooolllooooool;.      .         .',;;;;;,.                 //
//                .,;;;;;,.                  ;looooooooooollllllloooooooooool;                  .,;;;;;,.                //
//               .,;;,;;,.                  .coooooooooollloooollloooooooooooc.                  .,;;;;;,.               //
//               .;;;;;;'                   .:lllllllllllllllllllllllllllllll:.                   ';;;;;;.               //
//               .;;;;;,.        ............;clloolllllllllooollllllllloollc;............        .,;;;;;.               //
//               .'...,;,'....'',,,,;;;;;;,,,;:lllllllllolllooolllolllllllll:,,,,;;;;;,,,,,''....',;,...'.               //
//               ..   .,;;;;;;;;;;;;;;;;;;;;;;;:cllllllooolllllllloollllllc:;;;;;;;;;;;;;;;;;;;;;;;,.   ..               //
//                    .,;;;;;;;;;;;;;;;;;;;;;;;;:clcclllllloooooolllllcclc:;;;;;;;;;;;;;;;;;;;;;;;;;.                    //
//                  .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;:loooooooooooool::::;;;;;;;;;;;;;;;;;;;;;;;,;;;:,.                  //
//                 'cc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;loooooooooool;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:cc'                 //
//                'cl:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;',:clloooolc:,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lc'                //
//               'cll:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,...',;::;'...,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:llc'               //
//              'cllc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'...........';;;;;;;;;;;;;;;;;;;;;;,;;;;;;;;;;:cllc'              //
//             .:ooolcc::::cccc:;;;;;;;;;;;;;;;;;;;;;;;,...........,;;;;;;;;;;;;;;;;;;;;;;;:cccc:::::cloooc.             //
//             ;looooooollllooooc;;;;;;;;;;;;;;;;;;;;;;,...........,;;;;;;;;;;;;;;;;;;;;;;clooolllloooooool;             //
//            .cooooooooooolllloc;;;;;;;;;;;;;;;;;;;;;;,...........,;;;;;;;;;;;;;;;;;;;;;;cllllloooooooooooc.            //
//            ;ooooooooooooooollc::;;;;;;;;;;;;;;;;;;;;............';;;;;;;;;;;;;;;;;;;;::cllooooooooooooool;            //
//           .:oooooooooooooooollllllccc::::;;;;;;;;;;,.............,;;;;;;;;;;::::ccclllolloooooooooooooooo:.           //
//           .looooooooooooooollloooooooooollllccc::;,'.............',;::ccclllllooooooooollloooooooooooooool.           //
//           'loooooooooooooollllcc::::ccccccccccccccc:,...........,:cccccccccccccc::::::cclllooooooooooooool'           //
//           ,loooooooooooooolll:;;,,;;;;;;;;;;;;;:loooc'.........'coool:;;;;;;;;;;;;;;;;;:cllooooooooooooool,           //
//           ,looooooooooooollllc:;,;;;;;;;;;;;;;clooool;.........;loooolc;;;;;;;;;;;;;;;:clllloooooooooooool,           //
//           'looooooooooooolloool:;;;;;;;;;;;;:loooooooc'.......'coooooool:;;;;;;;;;;;;:coollloooooooooooool'           //
//           .looooooooooooolllc;;;;;;;,'';;;:clloooooool:.......:loooooooll:;;;;,'';;;;;;;cllloooooooooooool.           //
//           .cooooooooooollll:'',;;;;;,'',;;:llllllllolll,.....,llllllloll;',;;,..,,;;;;,'':cllloooooooooooc.           //
//            ;ooooooooooolllc;,;;;;;;:clcccccllcccclll;,;,.....,;,;lllccc:,,::c::;::;;;;;;,;clllooooooooooo;            //
//            .looooooooooool:;;;;;;;;coooooooolc;,,,,,,'.........',,,,,,;clooooooooc;;;;;;;;:looooooooooool.            //
//            .;loooooooooool:;;;;;;;;coooooolllllool:;:lc:,'.',:cl:;:lollllllooooolc;;;;;;;;:loooooooooooo;.            //
//             .cooooooooooolc;;;;;;;;:looooolloolodddolooolccclooolodddoloolooooool:;;;;;;;;cloooooooooooc.             //
//              ,loooooooooooc;;,;;;;;;:looooooooooddddollllooolllloddddolooooooool:;;;;;;;;;coooooooooool,              //
//              .;looooooooool:;;;;;;;;;:coooooooooddddolllodddoolloddddoloooooool:;;;;;;;;;:looooooooool;.              //
//               .;looooooooolc;,;;;;;;;;:clooooolodddc,:ooodddool:,cdddolooooolc;;;;;,;;;;;cloooooooool;.               //
//                .:looooooooolc;;;;;;;;;;;clooooloddc..:lodddddol:..cddoloooolc;;;;;;;;;;;cloooooooool:.                //
//                 .;loooooooool:;;;;;;;;;;;:looolodc...codddddddoc...cdoloool:;;;;;;;;;;;:loooooooool;.                 //
//                  .,loooooooool:;;;;;;;;;;;:loolol,..,lodddddddol,..,looool:;;;;;;;;;;;:loooooooool,.                  //
//                    'coooooooool:;;;;;;;;;;;:looo:...:odddddddddo:...:olol:;;;;;;;;;;;:loooooooooc'                    //
//                     .;loooooooolc;;;;;;;;;;;:lol,..;lodddddddddol;..,lol:;;;;;;;;;;;clooooooool;.                     //
//                       .:looooooolc:;;;;;;;;;;coc..;lodddddddddddol;..coc;;;;;;;;;;:cloooooool:'                       //
//                        .'cloooooool:;;;;;;;;;:l:';llodddddddddddool;':l:;;;;;;;;;:looooooolc'.                        //
//                          .':loooooolc:;;;;;;;:oc:lllodddddddddddolll:co:;;;;;;;:clooooool:'.                          //
//                             .,clooooolc:;;;;:lollolloodddddddddoollollol:;;;;:clooooolc,.                             //
//                                .,:clollllcccllllllloooodddddddoloolllllllcccllllolc:,.                                //
//                                   ...,clcc:cllllllloooodddddddoooollllollc:cclc,...                                   //
//                                       .....:lllllloooooodddddoooooolloool:.....                                       //
//                                          'cloollllooooodddddddooooolloooooc'                                          //
//                                        .,loollllllooolodddddddoooolllloooool,.                                        //
//                                       .:llllolllllloooodddddddoooollllooooool:.                                       //
//                                      .cloollollloolllodddddddddollloolooooooooc.                                      //
//                                     'clollllolllooolldddddddddddllooollooooooooc'                                     //
//                                    ,llllllolllllooolldddddddddddllooolloooooooool,                                    //
//                                   'llllllllllllloolllodddddddddollloollooooooooool'                                   //
//                                  .coolllollolllollooooodddddddoooolloollooooooooooc.                                  //
//                                 .;llllllllllollllooooooodddddoooooolllllooooooooooo;.                                 //
//                                 .:olloollloolllloooooooooodoooooooooolllooooooooooo:.                                 //
//                                  ;llloollllc,':ooooooooolc:clooooooooo:',cloooooool;                                  //
//                                  .':cllc:,..  ,loooooooc,. .,coooooool,  ..,:cllc:'.                                  //
//                                     ....      .:oooooc,.     .,cooooo:.      ....                                     //
//                                                .,::,..         ..,::,.                                                //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ILLI is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
