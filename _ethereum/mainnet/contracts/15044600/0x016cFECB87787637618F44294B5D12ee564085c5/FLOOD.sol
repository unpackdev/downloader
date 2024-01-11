
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FloodingFactory
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                     ..                                                         //
//                                                                    'do.                                                        //
//                                                                   .;xc.                                                        //
//                                                               ..............';c;.                                              //
//                                                           ..,:loo:........:ok0Kd'.                                             //
//                                                        ..,lxO0KKk:......:d0KKKKx;..                                            //
//                                                      ..;oO0KKKOkl'...',lOKKKKKKOl'...                                          //
//                                                    ..,lOKKKKKKko:,',,:x0KKKKKKK0kc'.....          .                            //
//                                                  ...;d0KKKKKKKkdl::cokKKKKKKKKKK0ko;'...........,:lol:.                        //
//                                                ....;d0KKKKKKKKK0OxkO0KKKKKKKKKKKKK0ko:;,'''',;cdO0KK0d'.                       //
//                                            ..''...,o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kkxxxxkO0KKKK0d;.....                    //
//                                        ...;oxkc'.'ckKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk:'..;ol.                   //
//                                     ...'cxOKOl,.':dOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo,..,dK0c.                  //
//                                   ....:x0KKOl,',;ok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx:''.,dKKk,.                 //
//                                 ....'lOKKKKd;,,;cx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0d;,'.,d0Kk;..                //
//                               .....,o0KXKK0o:;::oOKKKKKKKKKKKKKK000KKKKKKKKK00KKKKKKKKKKKKKKKKKKK0o;,'',lxd:...                //
//                            .......'lOXKKKK0xlcldOKKKKKKKKKKKK000O00KKKKKKK00O00KKKKKKKKKKKXKKKKKX0d:;,'',;,.....               //
//                          ........':xKXKKKXK0OkOKKKKKKXKKKKKK00OOO0KKKKKKK00OO0KKKKKKKKKKKKKKXKKKXKOdc::cokkc.....              //
//                      .....;okd:'',l0XKKXKXKKKKXKKKXKKKKKKKK00OOO00KKKKKK000OO0KKKKKKKKKKKKKKKKXXKXK0OOO0KKKd,.....             //
//                     ......;xK0l,,;d0XKXXXKKKKKKXKKKKKKKKKK00000000KKKKK0000000KKKKKKKKKKKKKKXXXXXXXXKKKKKKKk:........          //
//                ...........:k0d:,;cxKXKXXXXXXKXKKKKKKKKKKK000000000KKKK000000000KKKKKKKKKKKXXKKXXXXXXKKKKKKKx:'...'ld;.         //
//            ...............,loc:;:ldxxkO0KXXXKOoccok0KKKKKOdlloxxk00000xc;;:dO00KKKKKKKKKKKKKXXXXXXXXXXXKKK0d;,'',lOKd'.        //
//          .................':xOdc:,....,cx0KKd,...',d0KKKO:.....';lk0Ol'..'',oO00KKKKKKKKKKKKKXXXXXXKXXXKKKkl;,,cx0KKx,..       //
//        ............,oo;'',:xKKkdo'......'cd:...:o:'cOKKKk,........;c;..'coc,ck000KKKKKKKKKKKKKKKKXXXXXKKX0d:,,ckKKK0l'...      //
//      ..............:OKd;,cxKKKKK0x,..........,cl:,:x0KKK0x:...........,ll;,cxO0000KKKKKKKKK00000KKXXXXXKKkc;,,lOK0xl,....      //
//    ...............,o0Kx:cx0KXXXXXKOl..... ..,::,;lk0KKKK00Oo,. ... ..;:;,:dO0000000000000000OO00KKXXXXXKOo:,,,:odc,''.....     //
//    ...............,dK0xcoOKXXXXXXXXKx;. ...','':xOKKKKK00000k:.   ..',''ck0KKKKK00000000000000KKXXXXXXKKxc;,,,,,;cldxo,....    //
//    ...............':dxold0KXXXXXXXXKk;.   .....:dO00K000KKK0d,.  .......;ok0KKKKK000000000000KKKKKXXXXK0o:;;,,;lk0KKKx;....    //
//    ..............';ldoccoOKXXXXXXX0o.  ..  .....;lk0000KKKkc. ..... .....,cx0KKKKK0000000000KKKKKXXXXXKkl:;;;:oOKXXKkc'....    //
//    .............'':xK0kookKXXXXXKk;. ....'.......'cx00KK0d,. ....','.......;dOKKKKKKK000000KKKKKXXXXXXKkl::;:oOKXXX0d;.....    //
//    ............'',:xKXKkddOKXXXXO;  ...,cxxc....'..:x0KKk;  ...',lxko'...,'.;x0KKKKKK00000KKKKKKXXXXXXKxlc::lxKXXXKOl,.....    //
//    ...........'',,ckKXX0xodOKXXX0d;'',:dOKKOd;...'':x0KK0xc;,;cox0KK0kc...',ck0KKKKKK00000KKKKKKXXXXXXKkoccld0KXXXKkc,'....    //
//    ..........''',:o0XXXKOddx0KXXXXKOxxO0KKK00OdcloxO0KKKKKK0kO00KKKKKK0kddxk00KKKKKKKK0000KKKKKKKKXXXXKOdllokKXXXXKk:''....    //
//    ..........'',,:x0XXXX0kddkKXXXXXKK0000000000KKKKKKKKKKKKKKKK0KK0000KKKKKKKKKKKKKKKK0000KKKKKKKKKXXXXKOxxk0KXXXXKx:''....    //
//    ..........'',;cxKXXXXXKOkOKXXXXXKK000000000KKKKKKKKKKKKK0000000OkO00KKKKKKKKKKKKKKKK00000000000KXXXXXK000KXXXXXKd;''....    //
//    .........'',,;cxKXXXXXXKKKKXXXXKK0000000000KKKKKKKKK00000OkO00OxxO000000KKKKKKKKKKKK0000000000KKXXXXXXXXXXXXXXX0o;''....    //
//    .........'',,;cd0XXXXXXXXXXXXXXKK00000O00000KKKKKK000000OxkOOOkxxO00000000KKKKKKKKKK000000000KKXXXXXXXXXXXXXXXXOo;,'....    //
//    ........''',,;:oOKXXXXXXXXXXXXXK0xdolodxxdllddddddddddoolcclollcccloxOOO000KKKKKKKKK00000000KKXXXXXXXXXXXXXXXXXOl;,'....    //
//    ......''''',,;;:okKXXXXXXXXKKK0xlokOocdkkl',okOkd:';dkkOko;ckOXXKOc..;okO000KKKKKKKK0000000KKXXXXXXXXXXXXXXXXXKkc;,'....    //
//    ....'''''',,,;;:clx0KXXXXXXK0xc;;:ol,........,::,...;loo:'...,lol;..  'd00000KKKKKKKK00000KKXXXXXXXXXXXXXXXXXX0d:;,'....    //
//    ..''''''',,,,;;::cldOKXXXXXKx,...............''''.................... .cO0000KKKKKKKK0000KKKKXXXXXXXXXXXXXXXXKOl:;,''...    //
//    .''''''',,,,,;;;::clx0KXXXX0l............,:loooc::::cllllc:;,'.........:O00000KK0KKK000KKKKXXXXKKKKKKXXXXXXXX0xc:;,''...    //
//    ''''''',,,,,,;;;::clokKXXXK0l..........,lodoooc:lodoooooooooooc'.......:O000000KKKKK00KKKKKXXKK0000KKXXXXXXXKOoc:;,,''..    //
//    ''''''',,,,,,;;;::cclx0XXXKKx;;do,....:ooooooolooooooolllccllllc' .,dc,lOO000000KKK000KKXXXKK00000KXXXXXXXXX0xl::;,,'''.    //
//    '''''',,,,,,;;;;::ccld0XXXXK0kox0d;c;:oooooooooooooolc:::::::::ll;,co:cxkO000000KKK00KKKKXKK00000KXXXXXXXXXKkoc:;;,,,'''    //
//    '''''',,,,,,;;;;::ccldOXXXXXK0Oxdlodclooooooooooooolc:;;cddl::lOKOl,;lxxkO000000KKK00KKKKKK00000KXXXXXXXXXKOdcc:;;;,,'''    //
//    '''''',,,,,,;;;;::cclokKXXXXXKKK0kxc:ooooooooooooool:;,oKNNOd::lc:coxxxkOO00000000K00KKKKK00000KXXXXXXXXXKOdlc::;;,,,'''    //
//    '''''',,,,,,,;;;:::cclx0XXXXXXXKK00dcooooooooooooolc:''cllccc:cldxkxxxxkOOOO000000000000000000KKXXXXXXXXKOdlc:::;;,,,'''    //
//    .''''''',,,,,,;;;:::cloOKXXXXXXXKK0xccoooooooooolcc:;;:cldxxkkkkkkxxxxxkOkkkO00000000000000000KXXXXXXXXKOdlc:::;;,,,,'''    //
//    ...'''''',,,,,,;;;:::cld0XXXXXXXKK0Od::lllllllccc:;:lxkkkkkkkkkkkkxxxxxkkkxkO0000000000000000KXXXXXXXX0kocc::;;;,,,,''''    //
//    .....'''''',,,,,,;;;::clx0XXXXXXXK00Oxc;;;:::;;;:cldxkkkkkkkkkkkkkkkxxxkkxxkO000000000000000KKXXXXXXX0xlc::;;;,,,,,'''''    //
//    .......''''''',,,,,;;;:clx0XXXXXXKK000OxdooooooodxxxxxkkkkkkkkkkkkkkxxxxxxxkO00000000000000KKXXXXXXKOdlc::;;;;;,,,,'''''    //
//    '''',,,;;;::::cccccccllooxOKXXXXXXKK000000000OkxxxxxxxxkkkkkkkkkkkkxxxxxxxxkO000000000000KKXXXXXXX0Oxooooooolllllllc:::;    //
//    ;:::::cccllloooooddddddddxxO0KXXXXXXK0000000OOkxxxxxxxxxkkkkkkkkkxxxxxxxxxxkO00000000000KXXXXXXX0Oxxxdddddoooooolllllcc:    //
//    ;;:::cccclloooooooooodddxxxkkO0KXXXXXKK00000OOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxOOO00000000KXXXXXXKOkxxxxdooooooooooolllcc:::    //
//    ;;;;;;:;;::::cclllllllllllloddxkOKXXXXXK000OOOOxxxxxxxxxxxxxxxxxxxxxxxxxxxkOOO00000KKXXXXXK0Okdolllollloolccccccccc::::;    //
//    '''',,,;;:::::::::;;;;::clllllllodk0KXXXKK000OOkxxdxxxxxxxxxxxxxxxxxxxxxxkOOO000KKXXXXXK0kdoloolc:;;;;;::cccc:;,,,,'''''    //
//    ,,;;;;;:::;;;;;:::ccccclllcccllloodxkO0KXXKKK00OkkxdddxxxxxxxxxxxxxxxxxkO000KKKKXXXXKK0kdoolllloollc:::::::ccllc::;;,,''    //
//    ''''''''''''',;;::::;;,,,;;;:cccccccclodk0KKKKKK00OkxxxxxxxxxxxxxxxxkOO00KKKKKKKK0Okdddolc:::::;;:cll:;;;;;;;;;;;;;:;;,'    //
//    .........',,;;;;,,''',,,,,;:::;;;;;;:::clddxkO00KKK000OOOOkkkkkOOO000KKKKKK00Okxdlcc:::cl:,,,,,'''',;::;,'''''''.....'''    //
//    ...''',,,;;;,,,,;;;;;;::cccc:::::::::cclllcloodxkOOO00000000000000000OOOOkxdollcccc:::::clc:;;;;;;;;;;:cc:;;,,,,,''''...    //
//    ..'''''....''''''',,::::;,,,,,,,,,,;:c:;,,,,;;;;::ccclodooooolllllccc:::lc;;;;;,,,,,,,,,,;:l:;,;,,,,,,,,;;:c:;,,''''....    //
//    ................',;;,,'..........';;;'...............',,................,,.................,:;'............',,,'........    //
//    ..............',,,'............',;,.....................................''...................,;,..............'''.......    //
//    ............'''...............','................  ....                 ......................';,.......................    //
//      ..........................''......               ..                   ...            .........','.....................    //
//    .........................'','....................................................................';,'...................    //
//    ........................''.......                ...                     ...            ...........','..................    //
//    ....                ......                      ..                        .                         ....                    //
//                       .....                        .                         .                           ...                   //
//                     .....                         .                                                       ...                  //
//                   ....                           ..                           .                             ...                //
//                 ....                            ..                            .                               ..               //
//               ....                            ...                             ..                                .              //
//             ....                             ....                             ..                                 ..            //
//            ...                               ...                              ..                                  ..           //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLOOD is ERC721Creator {
    constructor() ERC721Creator("FloodingFactory", "FLOOD") {}
}
