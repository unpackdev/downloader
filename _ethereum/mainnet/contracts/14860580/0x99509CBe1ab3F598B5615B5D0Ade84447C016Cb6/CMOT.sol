
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CIELMOT Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    xxxxkkkxddollllooolcclodoodddxkxxddddddddoolcccoddl:'                                                                            //
//    oxxxxkkkxxxddooool::oxxxdlooloxxxxkkxxxxxxdddoooooc;.                                                                            //
//    lxxddxxddddooool:'',;okOkdllc:ldxxxxxxxxddddool:,..                                                                              //
//    dxxdoolc:;;,;oo:'..,,,cxOOdc:;;:ldddddooollc;'..                                                                                 //
//    xxxdolc:,''..cdc...,loloxkkxoc:;;:cllc::;''',..                                                                                  //
//    ddddolc;,''..'ol....,odxxxdddxxol:,,'.......';.                                                                                  //
//    ddddolc:;,'''.,,. .....,lxdccloddl;,...,;;,,,,,.                                                                                 //
//    ooooolc:;,,;:;'... .....;dxlldddkkdlc:codxddollc;.    ..                 ..,'.                                                   //
//    ddddolllccclolc,'.  ....:dxoldxdxkkxdoloodxkkxxddl,..;ll;.       .      .,oddc,.                                                 //
//    kxxxdxxxxxkkxxxo:.   ..'lxdc;:lloxxxxdolllodxxxxdddol:,',,,,.  .,c:'.   .;c,.':c:,..                                             //
//    xxxxxxxxkkkkkxxdl.    .'coc,',;:codooddolccldxxxdooddoc,...,. ..:odo;.   ..   ..;loc;'..                                         //
//    :lodxxxxxxxxxddo:......':olc;;::coddolool::ldxxxddlodxxdc. ... .'ldddc'.       .'.';clc:,..                                      //
//     ..,:lddddddoolc,..lkxdxxdddooooodxxdolllccoxxxxxddxxdxkkd:. ... .:oddo;.      .,,. ..',;;;,.                                    //
//        .,;:coddoolc,..lkkxxxdooddddxkkxxxoccc:lxxxxxxxxdodxdxd;. ... .':lol;.     .,.  ..    .',.                                   //
//       'lol:,:ooolc:'...lkkxxddoodxxxxxxkkkdc:ccloooollcldxxxxxc'........'::,,,'''',.    ..    ..                                    //
//      .;ddll;.,::cc;'...'coxxdxdollodxxxdxkkdl::;,',,''':ldkkkkdl:;;,'...... .......                                                 //
//       .cdlc;...';:::;'.'';c:::;,..,ldol;:cllc,''''''',;;:cloooc;,'.....                                                             //
//        .';:;..''..,cc;''.','..     ;l:,;ldxxdocclllll:::::clllc:'..                                                                 //
//           ...      .....'.....     .c:;cdxkkkkOOOkxxxxooolool:,'.                                                                   //
//                        .'.....      ':;:odxxxkkkkOOkkkxddddddc'..                                                                   //
//                        ';,''..       .,,:ldxxxkkkkkkkkkxddddxo,.                                                                    //
//                        .;;,,'..       ..';lddxxxxkkkkxkxxdddddl'                                                                    //
//                        .':;;,'...       ..';codddxxkkxkkkkxxxxxl'.                                                                  //
//                         .';:;,'..           ...;ccoxkkkkkkkkkxxxxd:.                                                                //
//                           .';;,'...             .''okxdxkkkkkkkxkkxl'                                                               //
//                             .......              ..:ddddddxxkkkkkkxdl;.                                                             //
//                                                   .'ldxdddxddkxxkkkxxdl'.                                                           //
//                                                    .lddolodoldddxkxxxdoc;;.                                                         //
//                                                    .,,,,'';c:cloddooolccllc,.                                                       //
//             ...                                   .;::cc:::ldoodxxdc::;;;:cl,.                                                      //
//           ...:l;.                                 .codxxoc:oxkkkOOOxdolc;,;;;'.                                                     //
//           ..,lxd:.                           .....'looodxdodkxxxxxxdool:;,,::,.                                                     //
//          ...;looc'.                         ......'lddl;;cldddodddddlcclc:c;''.                                                     //
//          ...'','''...                       ':;'...cooc:::ldoloooolllllolllc;,.                                                     //
//         ...',;;'........                    ,llc;'.':llcll:ll:::;;;;;;,''',;;,'.                                                    //
//         ............'''....                 .,cll:,'',;;;:;;ccc;'',,'.....''....                                                    //
//        ......... ............                 ..';,'..'......'','.....''..,'..                                                      //
//       ..........   ...   ......                   ...................';:,''...                                                      //
//       ..........   ........  ...                  ..................,;cc;'...                                                       //
//      ..','.,c:,.','............''...               ................,::c:;'..                                                        //
//     ..';odollddc;ldocc:,..............               ...........'',;:::;,'..                                                        //
//    ;;..';:codlcc:cdl;cdxo,..............               .......'',,;;::;,,..                                                         //
//    ;:,....',;,,,,;:cllodxo,.............               .......'',,;;;;,,,'.                                                         //
//    ccc,.......',',;;;:ldxkxl,. .......                 .......''',,,,,,,,;.                                                         //
//    ',,,;::,.......','..,:ldxxo;. ...                   .........''',,,,,;:;,...                                                     //
//    :c'..'..................',:l:.    ......  ......     .........'',,,,;::coool:;,..                                                //
//    ,'.........................,c:'. .....''',;:;,..     ....''..,,,,;:coodoooooodolc::::::;,..                                      //
//    ...........................,;cll:;::ccclll:;,'..........';;,,:cccloddddoooooddoooooooddddo:'.                                    //
//    .................,;;........,::;:oxdddxxdo:,''''..'',;;:ccc:coooddddxxxxxxxxddddoooooooollll;.                                   //
//    .................:od:,;;'....;c;,oxxxxxxdl:;;::::::cclloddddoooodxxxxxxxxxxxxxxxxdddoollccccc:.                                  //
//    .................,co:,;cc,...'cclddddddolccc:coolllodddxxxxxxxxxddxxxkkkkxxxxxxxddddoolc:::::::'                                 //
//    ..................;lc'.','',,,:cclloolc:clloodxxdddddxxxxxxddddxxxxxxxxxxxxxxddddoooolc:;,,,;;;;.                                //
//    ..................,::,...'',,;;;;;:c:;;:clldxxxxxxxxxkkkkxddooddxxxxxxkkkkkxxxxddooool:,'..'''','.                               //
//    ..................':c:'...'''''''',,,,:ccloodxxxxxxxxkkkxxxddooddxxxxxxxkkkkkxxxddolc:;.......'',.                               //
//    ....................,;...............';:clooddxxxxxxxxxxxxxxdoooodddxxxxxxkkxxxxdolc;'.......',;:;.                              //
//    .....................'................',:cloodxxxxxxxxxxxxxxdllllooddddddddddddollc,........',;;::;.                             //
//    ................................','..''',:cooooddddddoooooooc:;;:cclllllccccccc:;;,..........',,;:::'.                           //
//    ..........................,:c:';ldxdoc:;'',:ccclllllllcccccc:;,,,,;;;;;;;,,,,,,,'..............',,;::;.                          //
//    ......................;,';oxd:cdxkkkkxxxdlloc;;;;;;;;;;;;:::::;;,,,,;;;;;;,'''''......  .........',,;;;'.                        //
//    .....................,;,,cdklcloxOkkOkkOkxdoc,.''',,;:clooddddooolloddoooollc:;;,''...   ..........',,;;'.                       //
//     ........ ..........',cccldxocoodkkkkkkxxdoclc,',;clodxkkkOOOkkkxxxxxxxxxdddolccc:;,'.    ...........''','.                      //
//     ......   ....''..;l;',::ldxo:;:llloxxdxkkkxkxl:coddxxxxxxxxxxxdolloooooooooolcc:;;,'.       ............',,'.                   //
//     .....   ...'','...;'...':coo::cooodxkOkddxkxc;:loooooollllllccc:;;;::::::::ccc:;;:;'.          .........',:cc;'.                //
//      .... ...,;;;,,'......';::cc;,:loolcloddoc;;,,;:::;;;;;::::::::;;,,;;;;;;;,,;;::;;,.             ........';:cclc;..             //
//       .....';:cc:;,;'. ....,;,;c;',;;;,,,';loccc:;'''''',;;:cccc:::;;,,,,;;;;;;,,,,,,''.   ...'''..    ......',;;:cccc:,..          //
//         ..';clddl:;;'. ......,,;,'''''',;;;:loolc;'....',,;;:::::::;,'',,,,,,,,,,,'',;,'.,:lodxkkxoc;.   ...',;,;;::clllc:'.        //
//         ..;codxxdc,,,......'',;;:;;;:c:;::;;:::lc,.....''',,,;;;:::;,''',;:;,,,,,,;:c:;;::codxkOOOOOOxc.  ....'',;;;::cllll:'.      //
//         .,codkkkdl,.';.....;:,,clcc:;cc;'..':lc:;'......''',,,,;;;;;,,,cclxoloc::;;;,,,,,,,:clddxkkOOOOd,.  .....'',;;;::ccll:'.    //
//        ..:ldkkkxdc,..',...'oxc;locldcclc,',,',,,'.........''',,;cc:coc:ocldlxxc;,''........'',;;:cldxkkOkc.   ......''',;:cccll:    //
//        .'coxkkkdoc'...,;...;c,.',',;,.;c;,::,..,'..........';cldxxl:l::cccoxOd;...............',,;:codxkkko'   .........',;:cclc    //
//        .':clodddoc....','.............,:'.,:;.':,........',;:ccoddc',;:ccldkOl................',;:clooddxxxo:,;;:::::::::::ccccc    //
//        ..,;:cllloc'......................',,'':o:.',,,''',;::ccc:,'.';:clodkx;..................',:clooooodxdooooooooooooooooooo    //
//         .',;:cllool,....................';:;..;l:'',:c:::ccc:;;,'...';cldxkkl'.....................',;:clldxdooooooooooooooooooo    //
//         ..',;;::ccll;.........................';c:,,:ccloodl:'.......,coxkOOc..''....................'',;codxdoooooooooooooooooo    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMOT is ERC721Creator {
    constructor() ERC721Creator("CIELMOT Art Collection", "CMOT") {}
}
