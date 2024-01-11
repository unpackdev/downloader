
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AT THE MOMENTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//      _|_|    _|_|_|_|_|      _|_|_|_|_|  _|    _|  _|_|_|_| cccccccccccllcccccccllllllllllllllccccccccccccccccccccccccccccc    //
//    _|    _|      _|              _|      _|    _|  _|       cccccllccllllllllllllllllllllllllllllllllcccccccccccccccccccccc    //
//    _|_|_|_|      _|              _|      _|_|_|_|  _|_|_|   llllllllllllllllllllllllllllllllllllllllllllccccccccccccccccccc    //
//    _|    _|      _|              _|      _|    _|  _|       llllllllllllllllllllllllllllllllllllllllllllllllccccccccccccccc    //
//    _|    _|      _|              _|      _|    _|  _|_|_|_| llllllllllllllllllllllllllllllllllllllllllllllllllccccccccccccc    //
//    :cccccccccccccccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcccccccc    //
//    _|      _|    _|_|    _|      _|  _|_|_|_|  _|      _|  _|_|_|_|_|    _|_|_| llllllllllllllllllllllllllllllllllllllccccc    //
//    _|_|  _|_|  _|    _|  _|_|  _|_|  _|        _|_|    _|      _|      _|       llllllllllllllllllllllllllllllllllllllllccc    //
//    _|  _|  _|  _|    _|  _|  _|  _|  _|_|_|    _|  _|  _|      _|        _|_|   lllllllllllllllllllllllllllllllllllllllllcc    //
//    _|      _|  _|    _|  _|      _|  _|        _|    _|_|      _|            _| lllllllllllllllllllllllllllllllllllllllllll    //
//    _|      _|    _|_|    _|      _|  _|_|_|_|  _|      _|      _|      _|_|_|   lllllllllllllllllllllllllllllllllllllllllll    //
//    cccccccllllllllllllllllllllllllllllllllllllllllllllllllooolllllllllllcccclooolooooolllllloolllllllllllllllllllllllllllll    //
//    cccccllllllllllllllllllllllllllllllllllllloolloooooollc:::;,,,,,,,;;''';clloollooooooooooooooooollllllllllllllllllllllll    //
//    cllllllllllllllllllllllllllllllloooooooooooooooolccc:;,;:cc:::;'......':lllllc:::lloooooooooooooooooolllllllllllllllllll    //
//    llllllllllllllllllllllllloooooooooooooooooooooccccc:;;:cccc;''........',,;;;'....';cloooooooooooooooooooooolllllllllllll    //
//    llllllllllllllllllllloooooooooooooooooooooolc;;;,,'',,'',;'...    ..........     ...,cloooooooooooooooooooooooooolllllll    //
//    oooooooooooooooooooooooooooooooooooooooolc:,'''....... ..         ...... ...  .......':looooooooooooooooooooooooooolllll    //
//    dddddddddddddddddddddddddddddddddddddl:,'....                     ..... ...    ...   ..;looooooooooooooooooooooooooooool    //
//    dddddddddddddddddddddddddddddxdddoc:,......                          ....       .. .';cloooooooooooooooooooooooooooooooo    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:,... ....                                    ..   ..,;codxxxxddddddddddddooooooooooooooo    //
//    xxxxxxxxxxxxxxxxkkkkkkkkkkkkd:''.. ...                                      .... .....':oxxxxxxxxxxxxxxxxxdddddddddddddd    //
//    xxxxxxxkkkkkkkkkkkkkkkkkkkxl'.;,.  .                                             ......,lxxxxxxxxxxxxxxxxxxxxxdddxdddddd    //
//    xxxxxxxxxxxxxkkkkkkkkkkkkkl..,;.                                                  .....,lxkkkkkkkkkkkkkkkxxxxxxxxxxxxxxx    //
//    xxxxxxxxxxkkkkkkkkkkkkkkkd' .'..                                    ....             ..cxkOkkkOkkkkkkkkkkkkkkkkkkkkxxxxx    //
//    xxxxxxxxkkkkkkkkkkkkkkkkkl. ....                                  ...........       ..,okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxxkkkkkkkkkkkkkkkkxl.                    .....................''........      .,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx    //
//    xxxxxxxkkkkkkkkkkkkkkkkxdo,             ...',;;:::::::::;;;;;;;;;;;;,;::,...  ..   .'coxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx    //
//    xxxxxxkkkkkkkkkkkkkkkkkxdo:.          ..,:clooddddddddoooolllccc:::::::cc:'..  .. ..,cdxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxkkkkkkkkkkkkkkkkkkkxo:.         .,:clooddxxxxxxxxxxxxxxxddollcc::::::;..       .,:dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxkkkkkkkkkkkkkkkkkkkkkkxo:.       .,:looodddxxxxxxxxxxxxxxxxxxxxdoolcc:::,.....   .'cxkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxkkkkkkkkkkkkkkkkkkkkkkxdl,.     ..,:loodddddxxxxxxxxxxxkkkkkkkkxxxddolcc:'....   .;dkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxkkkkkkkkkkkkkkkkkkkkkkkkxxl.     ..,:loooodddxxxkkkkkkkkkkkkkkxxddoollllccc'      .lkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxkkkkkkkkkkkkkkkkkkkkkkkkko'      .,:loooddddxxxxkkkkxkxxdddl:;,'..'''',;,;,..   .;xOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxkkkkkkkkkkkkkkkkkkkkkkkkkkd,.     .,::::::::ccllodxxdddoc;,''..,,;::::::;..,.... .okOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkxc.     ...............'',,,'''',,;;:::ccccc:::;... ...'oOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkOOOkl.    ....',;;:::;'... ..,;,..;cc:;;'...;;;;;;:'.,'.,:cdOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkOOOOko'.';....',,;,'''',,'...:oxd:.;ooc:cc::cllllccl,,oo;;oldOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkOOOOOk:......',,'.''..'cc;'..cdxxd:';cdoooooddddxdoc;lxdl;okxkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkOOOOOOOx;....',;;;;:::ccllc'.'lodxxdc,,:dxxxxxkkkxo:;lxxdo:cdkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOx:...,:clooollooooc..;coddxxddl;;:cllllcccclxkxxdocldxkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOl'..',:lodddddol:'.,:cdxkkxxxddolcccclloxkOkkxxxdloxxkOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOl;'',;,;;::::;;;:cc:cldxkkxxxxxxxxkkOOOOOOkkkxxxddxxxkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOo;,',;:::ccclloddocc:;cloooc::lddxkOOOOOkkkkkxxxddxxxkOOOOOOOOOOOOkkOOkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOxc,,,;::cldddddxdl:;,',:clooooodxkkkkkkkkkkkkxxxxxkkkkOOOOOOOOOOOOkkOOkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxl;;;;;:cloddddxddlc:::clcccccldxxkkkkkkkkkkkxxxxkOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkxxkkkkkkkkkkkkkkkkxxxdddddddddo:;;;;:cllooodddol:;,;ccc;;:;;cllooddxkkkkkkxxdxOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkxxdddooooooodddddolllc:cclllooll:;,,;:clllllclllllcccldxxxxxxddxOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkxxdooooooooooooddddddddoc:ccccc::;;;;;;;:::ccccccllcclccodxxxxdddxOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkxddoooooooooooooooddddddddl:::cc:;:c:;;::ccllloodddooodxdddxxxxxdddxOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkxdoooooooooooooooooodddddddo:;:::cccllcccccllccclloooddxxxddddxddddxkOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkxdoooolllooooooooooooooddddddl;,;;:cccllllllcc;,,;:loddxxxdollodddoxkOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xkkkkkkkkkxdollcc::ccloollloolloooooddddoc;,,;::::cllllllc;::ldxxxxddolc:clooxkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xkkkkkkxxdolc:;;,',;;:cccccllllooooooooolc;,',,,;;:cllllolloodxxxxdolc:;;,:ldxkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxxxxxdolc;,,''..''',;;::;;;:c:;;;;;;;,'...''..'';:cccclccclloooolc:,,''':odxkOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    xxxdolc:;,,''.....''...'',,,,,,'........  ..''.....',,;::;;;;;::::;,'...,:ldddxkOOOOOOkxdodxkkxxxkkxxxddxxxxddxxxddxxxxd    //
//    ddolc:,'...................'''''''''...    .'''.......',,'...',''''...',ldxxddl,';:clol:,,;cdxoccll::cc:cllolclol:cllolc    //
//    lcc:;,'.....................''''''....    .'',,'....................,;ldxxxxdxo'     ..'''.,;:;,.....''''',,;,';;'',,;;;    //
//    l:;,''''''.'''.......................     .'',,,''.............',;:lodxxxxxxxddl,.      .............................''.    //
//    c:;',,,,,,''.''.................          .,,;;,,,,,'''',,,;;:clodddxxkkkkxxxddddxc.                     .       .......    //
//    cc:;;;;,'......................          .,;:::::::::;;::cclooddxxxxkkkkkkxxxxxdx0XOo,.                            .....    //
//    dolcccccc;,.................             .:ccccllllollllloodddxxxxkkkkkkkxxxxxxdxKXXX0o.                              ..    //
//    ddddddddolc;'............                'clllllloodddoooddxxxxkkkkkkkkkkxxxxxxoxKXXXXKx,                            ...    //
//    lll;;cclccc;..       ..                  ,clllllloodddddddxxkkkkkkkkkkkkkxxxxxdlxXNXXXK0k,                             .    //
//    ,,'.',,,,'..                            .;clloollloddxxxdxxxxkkkkkkkkkkkkxxxxxdlkXNNNXK00x.                                 //
//    ;;,.,,''..                              .;cloooolllodxxxxxxxkkkkkkkkkkkkkxxxxdllOXNNXXXK00d.                                //
//    :;'....                                 .cllooddoooodxxkkkkkkkkkkkkkOkkkxkkkxocoKXXXXXXK000d'                               //
//    ..                                      .okxdddxddooddxkkkkkkkkkkkkkOkkxkkkkdlckXXXXXXXK00K0d'                              //
//                                            .l00OOOOOkxdddxkkkkkkkkkkkkkkkkxkkkxocxKXXXXXXKK00000x,                             //
//                                             ;k000KKKKKKK0000OOOOOkkkxxxkkxxxddookKXXXXXXKKKK00KK0d.                            //
//                                             'dO00KKXXXXXXXXXXXKKKK00OOOOOkkkkkOKXXXXXXXXXKKK000KKOc.                           //
//                                             .ckOO00KKKXXXXXNNNXXXNNXNNXXXXXXXXXXXXXNXXXXKKXK000KK0x.                           //
//                                              ,x0000O00KKXXXXXXXNNNNNNNNNNNXNNNNXXXXXXXXXKKXK000KK0Oc                           //
//                                              .oKKKKK0OOKKXXXXXXXXXXXXNNNNNNNNNXKXXXXXXXKKXXK000KK00x.                          //
//                                               ;OKKKKKK0O0KKXXXXXXXXXXXXXXXXXXKKXXXXXXXKKXXXK000KKK00c                          //
//                                               .dKKKKKKK0OO0KKKKKKKKKKKKKKKKKKXXXXXXXXKXXXXXK000KKK00d.                         //
//                                                ;OKKKKKKKKOO0KKKKKKKKKKKKKKKXXXXXXXXXXXXXKXXK0O0KKKK0O;                         //
//                                                .oKKKXKKKKK0O0KKKKKKKKKKKKXXXXXXXXXXXXXKKXXXK0O0KKKK00o.                        //
//                                                 ;OKKKXXKKKK0000KKKKKKKKKXXXXXXXXXXXXXKKXXXKK0O0KKKK00k,                        //
//                                                 .o0KKKKKKKKK00000KKKKKKKXXXXXXXXXXXXKKKXXKKK0O0KKKKK00l.                       //
//                                                  :OKKKKKKKKK000000KKKKKKKXXXXXXXXXXKKKXXXXK0OO0KKKKK00x'                       //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ATMM is ERC721Creator {
    constructor() ERC721Creator("AT THE MOMENTS", "ATMM") {}
}
