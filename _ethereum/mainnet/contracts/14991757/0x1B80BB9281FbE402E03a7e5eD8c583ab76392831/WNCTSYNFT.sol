
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Why not choose to sell your nft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    K0XXXXXXXXKKNNNNNNNNNNNNNNNNNNNNNNXKklclllc;,;;;:;'...''',;:::::;,'',,;lOXXXNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    00XXXXXXXXKXNNNNNNNNNNNNNNNNNNNNNX0dc:cclc:;,,;;;;,'...',,;:cccc:;,,,,,;cxKXXNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KXXXXXXXKKXNNNNNNNNNXXXNNNNNNXXXkl:;;::cc:;;,;:;,,,'...',;ccccc:;,,,,,;;;oOKXXXNNNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KXXXXXXXKKXXXXXNXXXXXXXXXXXXXXKxc;;,,;:ccclc::c:;;,,;,''',:c::::;,,,,',,;;cxKXXXXNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KXXXXXXXKKXXXXXXXXXXXXXXXXXXXKx:;,'',;;:llllccccc:::cc:;,'',;;;,;,,,,,''',;cd0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KXXXXXXK0KXXXXXXXXXXXXXXXXXXKx:;;'.',',cccllcc::ccclodolc:,''',,,,,,,,'',,,;:o0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KXXXXKXK0KXXXXXXXXXXXXXXXXXKx:;;'.','';c::::::;;;:clodkxol:;''',,,,,,,''',,,,;oOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0KKKKKKKK0KXXXXXXXXXXXXXXXXXkc;;'..'''';;,;;;;;,,,;::cdkkxdlc;,,,,,'',,,'''',,;;lOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKK00KXXKKXXXXKKKKKXKX0l;:,..'''',,,,,,,,,,,,;::cdkkkxdlc:;,,,'''',,'''',,;;o0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKK00KKKKKKKKKKKKKKKKKx::;,..''''',,,,,,,,,,,;::cdxkkxxdllc;,,,'''',,.'''',;:xKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKK00KKKKKKKKKKKKKKKKOl;:;'..''''',,,,,,,,,,,;::cdxkkxxdoolc;,'''',,,'.',,,,;cOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKKK0KKKKKKKKKKKKKKKKKx:;:,...''''''',,,,,,,,';::cdxkkkkxddolc;''''',,,'.'',;,;dKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKK00KKKKKKKKKKKKKKKK0l;;;'....''.''',,,,,,,,,;::ldkkkkkkxxdolc;'''',;:;'..,,,'c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKK00KKKKKKKKKKKKKKKKk:;;;........'''',,,,,,,,;;:ldkkkxxdoolcc:;'''',,:c:'.',:ccxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKK00KKKKKKKKKKKKKKKKd;;;,........''',,;,,,,,,;;:oooollllloooolc:,''',;co;'';oddxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKKK00KKKKKKKKKKKKKKK0l,;,,..........',;,,,,''',:loollllodddddddolc;''';:ol,,:llloOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKK000KKKKKKKKKKKKKKKk:,;,'...........'''....';codddoollc:,,,,;::cc:;'',;clc:looc:xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKK00KKKKKKKKKKKKKKKKx;,;,'............'',,;:codxxxdoll:;'...';:;;:ll:,',:lccodl;.lKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKK00KKKKKKKKKKKKKKK0o,;;,'........',;:cllllllodxxxdolc;c:;,;clooodddo:,,;cclddl'.:OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKK00KKKKKKKKKKKKKKKOc,;;,'.......',,,,',;:ccccoxxxxdolclloooddxxxxxxdoc;,;coddl..,xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKKK00KKKKKKKKKKKKKKKk:,;,,'..........''..',:cccldxkkxxdddddddxxxxxxxkkxxo:;:dkx:..'oKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK000KKKKKKKKKKKKKKKx;',,,'..........,;:cclllllldxkkkkxxxxxxxxxxkkkkOOOkkd::dko....l0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK00KKKKKKKKKKKKKKK0o,';,,'.........,:cllooooolldkOOOOkkkkxxxxkkkkOOOOOOOkocc:'....:OXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK00KKKKKKKKKKKKKKK0l',;,,'........';clooddddolldk000OOkkxxxxxkkkOOOO00OOOkc''.....;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK00KKKKKKKKKKKKKKKOc',;,''........';looddddddllokO00OOkkxddxxxxkkOOOOOOOOx:.'.....,dKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK00KKKKKKKKKKKKKKKk:',;,'''........;loddxxxxdoloxkO0OOOkxdxxxxxxxkkOOOOO0d,.''....'l0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKKK0KKKKKKKKKKKKKKKKx;',;,'''........'clodxxxxdollodkkxdxxxxxkkkxxddxkOOOOOc..''.....:kKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKK00KKKKKKKKKKKKKKK0d,,,;,'''.... ....'coodddoooolllddoddxxxxxxdoloodkOOOOl...''.....,dKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KKKK00KKKKKKKKKKKKKKK0o,,,,,''''...      .;looollclllloooooddxxxdlldxxxkOOOo.....'.....'l0XXXXXXXXXXXXXXXKXXKKKKKKXXXXXXXXXXX    //
//    KKKK00KKKKKKKKKKKKKKK0l,,,,,''''....      .':oddolc:;:cllooddddoodxxxxkkkkx:  ....'.....:xKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXX    //
//    KKKK0KKKKKKKKKKKKKKKKOc,,,,,''''.....       .':loolc::cllllloooddxxkkkkkkxdl.  .........,lOKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXX    //
//    KKKK0KKKKKKKKKKKKKKKKOc,,,,,'.''.....          .,clllccclllloddxxxkkkkkxxxdoc.  ..... ...,dKKKKKKKKKKKKKKKKKKKKKKKKKXXXXXXXXX    //
//    KKKK0KKKKKKKKKKKKKKOkd:,',,,'.''.....            .':loooooddxxxkkkkkkkxxxxddo:. .....  ...,d0KKKKKKKKKKKKKKKKKKKKKKKKKKKXXXXX    //
//    KKKK0KKKKKKKKKKKKOo:;;;'',',,'',...... .           .;cloodxxxxkkkkkkxddxxddooo'  ..........'oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKx;'';;;'.,',,,','.......           .,:cloodddxxxxdddddddddolcoc. ..........',:loxkO00KKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKK0KKKKKKKKKKXO:..';:;..,,,;,','.......          ..;:clloooddddoooodddddool:ox' ...........'''',,;clodddxOKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKd'..';:,..,,,;,,,,.......         ..';ccloooodddddooodddooolc:lOl.............'''''''',,,,,:d0KKKKKKKKKKKKKKKK    //
//    KKKKKXXKKXKKKX0c...,:;'.',,,;,,,,'.....          .,,:llloooodddddoooooooollc:ckk'..............''....'''''';d0KKKKKKKKKKKKKKK    //
//    KKKKXXXKKXXKKKx,..';:;'.',,,;;,,,,'.'..         .;;,:llooooddddddddoooooollc:ck0:................'''.......'cOKKKKKKKKKKKKKKK    //
//    KKKKXXXXXXKXKx;...,;;,..',,,;;,,,,,''..        .,:;;clooodddddddddddddooollccckXo...................'......',o0KKKKKKKKKKKKKK    //
//    XKKKXXXXXXKX0c...',;;'..',,,;;;,,,,''..       .;::;:oooodddddddddddddddooollclONk,.........................'';x0KKKKKKKKKKKKK    //
//    XKKKXXXXXXKXO;...,;;,'..',',;;;,,;;,,..  ....':l:,:looddddddddddddddddddooolco0N0:..........  .............'',lOKKKKKKKKKKKKK    //
//    XKKXXXXXXXXKd'..,;;;,...''',,;;,,;;;,.. ....,llc;:oooddddddddddddddddddddoolldKNXo......... ...............''';x0KKKKKKKKKKKK    //
//    XKKXXXXXXXXKc..';;;;'..'''',,,;,,;;,,......;ll::codddddddddddddddddddddddooolxXNNk'.........................'',lOKKKKKKKKKKKK    //
//    XKKXXXXXXXX0:..,,,;;'.'',,,,,,;,,;;;,....':ccclooodddddddddddddddddddddddddolkNWN0:.........................''';xKKKKKKKKKKKK    //
//    KKXXXXXXXXXk;.',,;;,'.'',,',,,;;,;:;,...,;cldddddoodddddddddddddddddddxddddolkNNNKd'........................''';xK0KKKKKKKKKK    //
//    KKXXXXXXXXXk,.',,,,''.',,'',,,;;;;::,',;:cdkOkdddoodxddddddddddddddddxxxdddooONNNN0:........................''';xK0000KK0KKKK    //
//    KKXXXXXXXXX0:.',,,,'''',,'',,,;;;;c:,;:okkkO0OxdddodxxxddddddddddddddxxxxxdolkNNXNXo........................''',d000000000000    //
//    KXXXXXXXXXXKl'',,,''.',,,,'',,,;;;::;:x00OOOkxdddddodxxxddddddddddddxxxxxxxdldKXKXNk,.......................''':k000000000000    //
//    KXXXXXXXXXXXd,',,'''''',,,'',,,,;;::cx0OkxdodddddddooddxxdddddddddddxxxxxxxdllkKKXNKc.........................'o0000000000000    //
//    KXXXXXXXXXXXd'',''''''',;,'',,,,,;:lxOxoooooddddddddoodddddddddoooddxxxxkkxdloOXXKXXo.........................;k0000000000000    //
//    KXXXXXXXXXXXo''''..''',,,,,'',,,,;lxkolooooddddddxxxddoddddddoooloddxxxkkkxdllkXX0KXk'........................lO0000000000OOO    //
//    XXXXXXXXXXXXo''.....'','',,''',,;:dxdooooodddddddxxxxxdddddoolllloddxxkOOOkdoco0X00X0;........................cO000000000OOOO    //
//    XXXXXXXXXXXk,......'',,.',,''',,,cddddooooddddxxxxxxxxxddoolcccloddxxkkOOOkxxdokXK0KKc.................. .....cO00000OOOOOOOO    //
//    XXXXXXXXXXXo.......,;;c:,''',',;;cooddxdddddxxxxxxxxxxxxddo:;cllodxxxkOOOOOOOOxd0X00Ko................  ......lOOOOOOOOOOOOOO    //
//    XXXXXXXXXXXl.  ....'::cl:..'',,;::codxxxxdddxxxxxxxkkkxxxdl::loodxxxkkOOOO0000OxkX0OKx'..............   .....'oOOOOOOOOOOOOOO    //
//    XXXXXXXXXXO;.. .....',''....,cl::::ldxkkkxxxxkkkkkkkkkkkxdl:coddxxxkkkOOOOOOOOOxxKKOKO;.',,........     .  ..,dOOOOOOOOOOOOOO    //
//    XXXXXXXXXKo......,;.',,;;;:cloddc::ldxkkkkkkkkkkkkkOOkkkxxlclddxxxkkkOOOOOOOOkkxx0X000ocdkko,....         ..'lkOOOOOOOOOOOOOk    //
//    XXXXXXXXXk,..';coxxdddddddddddoollccoxkkOOkkkkkkkkkkkkkkxxlldxxxxkkkOOOOOOOkkkkkkOK0Okkkkkkko,.          ...lkOOOOOOOOOOOkkkk    //
//    XXXXXXXXXd.,okOOkkxxxxxddoodddddllooodkkOOOkkkkkkkkkkkkxxdlldxxxxkkkkkkOkkkkkkkkxk0Oxoloddxddo,.          .:kOkOkkOOkkkkkkkkx    //
//    XXXXXXXXXklxOOkkxxdddddddddxxxxdolooddxkkOOOOkkkxxxxxxxxdoloddxxxxxkkkkkkkkkkkkxxkxdoccoodkkkkkdoc;.      'dOkkkkkkkkkkkkkkxx    //
//    XXXXXXXXXXOxxkOOkxxxxxkkkxxddddxkkooodxxkkOOOOkkkxddxddddlcodddddxxxxxxxkkkxxxxddxdoolodxkkkkkkkOOOxc.   .okkkkkkkkkkkkkkkkxx    //
//    XXXXXXXXXXKkxO0000Okkxxdddddxxkkkkdooddxxkkkkkkkkxxdoddol::lodddddddddxxkxxxxxdooooxkxxxxxxdddxxkkkkkc....:kkkkkkkkkkkkkkkkxx    //
//    XXXXXXXXXXX0O000Okkxddddddxxxxxxddxdoodddxxxxxxxxxxdooolc;:llooooooodxxxxxxxdddddoldxxkkkkkkkxxkkOOkx:....ckkkkkkkkkkkkkkkkxx    //
//    XXXXXXXXXXXOdxxxxxxkkkkkkxddoddxxxxxoooddddddddddddddolc;';cllllllodxxxxddddooodkkxddddddxxkkkOOO0OOx,.. .lkkkkkkkkkkkkxxxxxd    //
//    XXXXXXXXXX0c';:coxkOOOkxdooddxkxdodkOOkdddddddodooooooc,..,:cccllodoodddddooolclodxkkkxddddddxxxxxkOd,.. ,dkxxxxxxxxxxxxxxxdd    //
//    XXXXXXXXX0c......,ldxxxxxxxxxdoc;cdxxkOOOkdooooooooolll;...,cllooooooooooooddoloolloodxxkkkkkkkxxdddc...,oxxxxxxxxxxxxxxxxxdd    //
//    XXXXXXXXKo....    ..;oxkkxddo:.. .'cdkkkO00Oxoccccccccllc:cclloloooooodxk0KKKkoodddddoooodxxkkOkdc;'...,dxxxxxxxxxxxxxxxxkkO0    //
//    XXXXXXXXO;....       .;ccc:;'       .;oxkkkO00kdc;;;:::cccccccccclloxkO0K0Odc,..;codxxxdddxxdddl.   ...,dxxxxxxxxxxxkkOO0KKKK    //
//    XXXXXXXXx....           ..            .';lxkkkO00Odl::::ccc::;;;:ldxkkxo:,..     ..;clodddxdl;.       ..:dxxxddxxkkO00KKKKKKK    //
//    XXXXXXXXd....                             .,:oxkkO00koc:::ccloodxxdl:,..            .;:cclc,.           .lxdxxkkO0000KKKKKKKK    //
//    KKKKKKKXO,  .                                ..,:ldk00Odlodddolc;'..                  ....             .'lkkOO00KKKKKKKXXXXXX    //
//    0KXKKKKXKc.                                       .';cdxdl:,'...                                    .,cokO0KKKKXXXXXXXXXXXXXX    //
//    dxkO0KXXKk,....                                       .'....                                  ...,cokO00KKKKKXXXXXXXXXXXXXXXX    //
//    ooloodxk0O;...........                                                              ...   ..,lxxk000KKKKKKKXKXXXXXXXXXXXXXXXX    //
//    oooooollo:. ...........                                                            .:ddddxkO0KKKKXXXXXXXNNNNXXXXXXXXXXXXXXXXX    //
//    ooooooool;....  ......                                                        ..';lx0KKXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXX    //
//    ooooool:,'....                                                           .;codk0KXXXXXNNNNNNNNNNNNNNXNNNNNNNNNNNNNNNNNNNNNNNN    //
//    oollc::,.....                                                        .,lk0XNNNNNNNNNNNNNWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    llccclo:.....                             ...',,;,,,,''...         .ckKNNNNNNNNNNNNXXNNNWWWWWWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNN    //
//    llooddo:......                        .',::ccclllllllcc::;,'.....'lOXNNNNNNNXXXXXXXNNNNNNNNNNNNWWWWWWWWWWWWNNNNNNNNNNNNNNNNNN    //
//    odddddoc'......                    .':cooooddddddoooollllcc:::clxKXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWNNNNNNNNNNNN    //
//    xxxxxddo:'.....                 ..;loddxxxxxkkxxxddoooollooxOKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWNNNNNNNNNN    //
//    xxxxxdddo:'..                  .;lodxxxkkkkkkkkkxxddooodk0XNNNNNWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNNN    //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WNCTSYNFT is ERC721Creator {
    constructor() ERC721Creator("Why not choose to sell your nft", "WNCTSYNFT") {}
}
