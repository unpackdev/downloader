
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RockMe TommyBoy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                ..'',,;;;;;,,..      ...                                    //
//                                             .';:clllllllcllllc;',:::::;;;;,,..                             //
//                                           .':cclolclllllllccccccccodolccccclc:'.                           //
//                                         .':looodddooodooolllllccc:cooolllccclloc.                          //
//                                       .,clodxddoolllooooollllccc:::coddoodolllcoc.                         //
//                                     .;loooddollccooddddddoooooll::::coooddolccc:lc,.                       //
//                                   .,loooooollllodkxxxddddxxxxddoolc:::loollllllloool'                      //
//                                  .:oooolllccloooocccccccccllloodddol:;clllooddddxddxdo:.                   //
//                                 .cdoollccccooc:;:clllllllllcc:::looooc:clddddxxddddddxko,.                 //
//                                .lxdolclllloc:;;:ccc;'''''',,,;c:::clol;;coddollllllllllooc.                //
//                               .:ddoolllooolcclccco:.   .  .. .cxdoc::c,';clc,.....,clllcll;.               //
//                              .,ddloooodxxxdoccllldl,....     .lOOOkdc,,,;coc. .. .',oxdoll'                //
//                              .lxoodxxxdddddoooc;,;:clll:;'...,lddddd:'',;co,  .. . .ckxkxo'                //
//         Cheers Ser!         .,odoxkxdllllooooooc:;,'',,;:cccclllllllc;,,:cc;'......,loooo;.                //
//                            .,loooxxocclooollllllllc:;;,''''',,,,,,,;:loollc:;;;;;::::cc:.                  //
//                         . .:oolloddlllol:;:::cclclllllccc::::::::clooddoooolc;'','',,;lo'                  //
//                   .      .cxxoclddllol:,'.''',;:cccllllccllloooooooooooollllllllcccccloxl.                 //
//                         .'ldoc::odlclc;'....',,,;::ccccllllllllllllllllccccccclllllloollo:.                //
//                   . .  ..;llc:;:loc:cc:,''.....',,,;:::::cccccccc::ccccccc::::cccllllcllc;:'               //
//                   . .. 'lollc:;;clc:;;::;,''........'',,,;;::::::::::::cc::::::::::c::c:;,;.               //
//                    .. 'x0dllc:;,;cc:::::::;,,''''''...........'',,;;;;;;;;;;;;;;;;;;;;;;;'.                //
//            ..  ... ..'x0kxdlc;;;,;:ccc:::::;;;,,,,'',,;:cc;''''.............''......'',lc.                 //
//           ..   ....',:xkkxdooc;,,;cddddl;;,,,',,''''',,;::,''',,,,,,,'''.''.........'',;'                  //
//    .......  ..........';cddooooc;;lxc'''.....,:c:,'...':l;'..............'''..''''',,;;..                  //
//    ...................  ..;loooooll:'.......:llllc,...'oxc,''''..................'',;c;                    //
//    ................        .':llodo:'.....;ccc:;,,,,;:;;;,,;;;;;;,,,,,''''''''',,,,;:;.                    //
//    ..............            ..,ldl;'',,cllc:;''',;cool;.',,,,,;;;;;;;;;;;;,;;;;;;;;:,.                    //
//    ..............              'odl:;loc::;;'..';clcccc,...'',,,,,;;;;;;,,,,,,,,;,,;;,..                   //
//    .............              .lxxddol:,,,'..':::;;;;;,......'''',,,,,,,,,,,,',''..,;;,'.                  //
//    ..........                .cxdddoc,'....',;;;'..','.   .......'''''''''''...'.. .'',''..                //
//    ..........               .;ddool:,'''',,,'.....,;,..          ........           ..........             //
//    .......                  .oxolc;,,,,,,'.......';;..                                ..... ...            //
//    .....                  .'lkxl:;,,''''.......'''''.                                   ...   ...          //
//    ......               .,coxdl:,,,'''.......''.. ....         .........                       ....        //
//    .....             ....:olc;,,''.'...........     ..     ...':;,;:;;:,'.      .               ....       //
//    .....            .....':cc;................           .';::cc:;;c,..;::,.   ..                ...       //
//    ....           ....... .',;;'.............           .'::ccccc:;c:,;::::;,',,.                  ..      //
//    ...          ........    ..','..........               .;:ccccc::::::cccc:::'                    .      //
//    ....      ......            .........                   .,cc:cc::::::ccc:::;.                    ..     //
//    ..      ....                   .....                      .;ccc:;::;;:cc:::'                      .     //
//           ...                        .                        .,:::;;'..;::::;.                            //
//                                                                 ';:;,;,,;:::;'                             //
//                                                                  .,;,;;;;:;;'.                             //
//                                                                   ..',;;;;;,.                              //
//                                                                     .,'.','.                               //
//                                                                      .. ...                                //
//    .                                                                  ....                                 //
//    ...                                                                  ..                                 //
//    ....                                                                                                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RMTB is ERC721Creator {
    constructor() ERC721Creator("RockMe TommyBoy", "RMTB") {}
}
