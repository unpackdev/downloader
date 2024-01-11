
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chalk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//    .POPIL.........................'lxxxxxxxxxxxxkkkkkkkkkkkkkkxdddc.........vvvvvpp.........p;:ccc:    //
//    .LOVE................////?????..:dxxxxxxxxxxxkkkkkkkkkkkkkkkxxdo......VVVVVVVp...........p..:ccc    //
//    .YOU.............////?????......'cdxxxxxxxxxxkkkkkkkkkkkkkkkkxxo;.......vvvvp.............p';ccc    //
//    ................////?????....',coxxxxxxxxxkkkkkkkkkkkkkkkkkxo:....//...vvvvv...............pcccC    //
//    ..2022.......////...........',;:ldxxxxxxxkkkkkkkkkkkkkkkOOkxc....x//////VVVVV...............pccc    //
//    ..0505.....////............//,',:coxxxxxxkkkkkkkkkkkkkkkkkxdl,..xx.........vvv..............,:cc    //
//    ...........//.........////??''.';;:cldxxkkkkkkkkkkkkkkkxdddol;.x....',.....vv...............,:cc    //
//    ;;;;,,,.........////////??.,'',cl.lllodxkkkkkkkkkkkOkxdddxxxx..,'',;c:'........vv...........,:cc    //
//    ||;;,,,'...../////////?...',,:co.dx..dodxxkkkkkkkkkkxddxkkkk..kxdooddo:.....vvvvv...........,ccl    //
//    ||;,,,,,'..////////////...';ccodxxxxk.xxxkkkkkkOOOOkddxkOOO.OO0OkkkOOkxc........vvv.........;cll    //
//    ||,,,;;,..////////.......,:codxkkkkkkk.kkkkkkOOOOOOkddkOOOOOOOkxdool--ol;.........vvv...''..;cll    //
//    ,,,,,;,'.////////......+/-..cccloxkkkkkkkOOOOOOOOOkxxkO00Oxl;'...'',;::,c;'..........vv.',,';coo    //
//    ,,,,;;,..//////...p...............':okkkkkOOOOOOOOOkxxO00Ol'.........,,ooxxl,.........vv..,,,;;c    //
//    ,,,;;;,...////....ppp://.........'::cdkOOOOOOOO0000OOO00Kk.,'....'..,,xkO000kdc:;;,'...v'''...:c    //
//    ,,;;;,'...a.......cooooc+,......'lxkxkOOOOO0000000000KKKKK0kdooo-,,,OOO000KKXXXK0)dol:;;:clc:cod    //
//    ,;;,'....a.pp....;;xxxxdlN-,,;;cldxkkO00000000KKKKKKKXXXXXXXXXXXXXXXXXXXXXNNNNNN).KXX..)kkxxxxOO    //
//    ,,;,,'..ap..'',ll..O000OOkxkkOO000KKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWW)//NN/..)XX0kxk0K    //
//    ;;;::,.p ..';:,:dd..O0000OOO00KXXXNNNNNNNNNo.NNNNNNNNWW.xWWWWWWWWWWWWWWWWWWWWWW)/WW//.)WWNNXXNNN    //
//    ;;;;;'.//...';,/:oc:lxkkkkkOOOO0000KKKKKKKKKK.kkKKKKXX.XXNNNWNWWWWWWWWWWWWWWWN0)/X....)XXNNNXO0K    //
//    ;;;;,../....';//';c;,lxkkkkkO00OOOO000000Okxxkk.._.O.00KXNNNNNNNNNNNNNNNNNNNX0)Oo..xdOXXX0dl.dkO    //
//    ;;;,].///////;;;,'''.'lxxxkkkOOOOOOOOOOOOOOkxxkkkkkkO000KXXXXXXNNNNNNNNNNNNXX)lc.)cl;ckK00Oo;:co    //
//    ::////////////////.....oxxxkkkkkkkOOkkkOOOOOOO0000000KKKKKKXXXXXXXXXXXXXXXXKk:...;c;'ckOOxoc,,;c    //
//    :]:;.////////////.......;dkkkkkkkOkkkkkkkkOOOOOOO000000KKKKKKKKKKXXXXXXXXXKKk:....;,.'coxko:,'''    //
//    :;.////////........,..v...:xkkkkkkkkkkkkkkkOOkkxxxkkkddddxkO00KKKKKKKKKKKK............;:codc,'''    //
//    :;.////////..........p.....;dxxxkkkkkkkkkxoc:;,'..'"'.....'xxxx0KKKKKKKKK.............;;;;;;;'''    //
//    .....///////........p.......lxxxxkkkkkkkKoooo;.........."xxxxx000000000...:.........//..........    //
//    .......///////.......p........:oxxxkkkkkkkkkxxddoooodxkOOOOOOO00000Oxl,................AD3......    //
//    ......./..///////....pp.........xkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOxc'.....................ABD......    //
//    ....///......./////..p...........,:ldxkkkkkkkkkkkOOOOOOOOOOOOOko;../..............Love.you.to...    //
//    ..////..............p...............',;cldxkkkkkkkkOOOOOOOOkxdl,..//..............The.Moon.and..    //
//    ./////............pp.............',;;;..:clodxkkkkkkkkxdoc;,'...///..................Back.......    //
//    ...............ppp.....:......:::::cclllll:loool.:::::cclllllcc:..'''...........................    //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract M001 is ERC721Creator {
    constructor() ERC721Creator("Chalk", "M001") {}
}
