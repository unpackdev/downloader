
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMIC AND MINT DISK
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//     _______ _     _ ______  _______ _______                                       //
//    (_______|_)   (_|_____ \(_______|_______)                                      //
//        _    _______ _____) )_____   _____                                         //
//       | |  |  ___  |  __  /|  ___) |  ___)                                        //
//       | |  | |   | | |  \ \| |_____| |_____                                       //
//       |_|  |_|   |_|_|   |_|_______)_______)                                      //
//     _______ _______ _       ______                                                //
//    (_______|_______|_)     (______)                                               //
//     _____   _     _ _       _     _                                               //
//    |  ___) | |   | | |     | |   | |                                              //
//    | |     | |___| | |_____| |__/ /                                               //
//    |_|      \_____/|_______)_____/                                                //
//     _______ _______ _______ _ _______  ______                                     //
//    (_______|_______|_______) (_______)/ _____)                                    //
//     _       _     _ _  _  _| |_      ( (____                                      //
//    | |     | |   | | ||_|| | | |      \____ \                                     //
//    | |_____| |___| | |   | | | |_____ _____) )                                    //
//     \______)\_____/|_|   |_|_|\______|______/                                     //
//                                                                                   //
//     ......   .......................,lkNMMOl0MMMMMMMMMMMMMMMMMMNx;............    //
//    ............................';cokKNWMMNxxNMMMMMMMMMMMMMMMMMMMO:'...........    //
//    .......................,cox0XNWMMMMMMW0kNMMMMMMMMMMMMMMMMMMMMKl,'''.'..'...    //
//    .'..''''.'';:;,,,,:cok0XWMMMMMMMMMMMMMNK000XWMMMMMMMMMMMMMMMMWd,''''''''...    //
//    ''''''''''';xXXXXNWWMMMMMMMMMMMMMMMMMMMMWX00000XWMMMMMMMMWNX0Oo;'''''''''''    //
//    ''.'''''''';kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK0O0NMMMXkxxkxddc,'''''''''''    //
//    ''.'''''''';kMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMOl0MMNxo0K0kxK0c'''''''''''    //
//    ''''''''''',kWMMMMMMMMMMMMMN0xoclxOXWMMMMMMMMMMM0o0WWWOdxkKXxxXx;,'''''''''    //
//    ''.','''''''oWMMMMMMMMWXKOo:,;cdO0OKWMMMMMMMMMMMWxdkkkx::k0XNkOKd;,,',,''''    //
//    ,,'',,,',,,,:dk0XWMMMWx,',;oOXWWNNXXWMMMMMMMMMMMMKl,';c;:OxxNOd0x;,,,,,,,,,    //
//    ',',,'''',,;,..':OWMMWkdk0KOxdoddloONMMMMMMMMMMMMWk,..'':l:oOodKo,,,,,,,,,,    //
//    ,,,,,,,,,,,,;;cdxkXWMMMMXko;,:clx0NMMMMMMMMMMMMMMMXl....cc;dxOKk;,,,,,,,,,,    //
//    ,,,,,,',,,,,,'',;c0WMMMMWNNXKXNNWMMMMMMMMMMMMMMMMMWk'....'dNW0o;',,,,,,,,,,    //
//    ,,,,,'.',,,,'..,cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;.....,oxc,;;,,,,,,,,,,,    //
//    ,,,,,''..,,,,.'cdKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.......,,..',,,,,,,,,,,,    //
//    ,;;;;,...,,,,.,lxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;........;kd,...,;;,,,;;;,    //
//    ;;;;;,'..';;;,''cKMMMMMMMKKWMMMMMMMMMMMMMMMMN0x;...........:dc.;;',;;;;;;;;    //
//    ,;;;;;;,,;;,,;;,,dXXKkk00kKWMMMMMMMMMMMMMMMWk,............;;:d:::..',;;;;;,    //
//    .,;;;;;;;;;;;;;;:oo:,',clokXWMMMMMMMMMMMMMXx;'...........,kd,d0oc;..,;;;;;;    //
//     ..;;;;;;;;,,;;:;;,........;ldk0XWMMMMMMMWO;.............lKx:kWOodc,,;;;;;;    //
//    '. .,:;;;:;,,;;,'',:c:cldol:;'..,cOWMMWKkOd'............'kWKx0XxxXNk:,;;:;;    //
//    ;;'..';:::::::;;dOdkK0OOOOOdl:'...'o0Kx,................:KMKolcdXMMNOo:,;::    //
//    :::;'...';;:oOddXWxlOOxkOOkxdc,.....,;'...............';kNKo;:kNMMMW0K0:,::    //
//    :;;;;'. .':cdxOXWM0:lkxxdlcoOx:;.....................ckXWW0OKNWMMMMWO0Wk,';    //
//    ........;lc:oKWMMMNdcl,'',,:xo'...................'ckNMMWKXWMMMMMMWXkKMK:''    //
//    ',,,,'',;ld0NMMMMMMO;.........',................:d0WMMWX0XWMMMMMMNOdkNMXddk    //
//    :::,;::lkNMMMMMMMMMNx'....................,ll:;oXMMMWXOOXMMMMMMWXKddXMMXx0M    //
//    cc:;:coKMMMMMMMMMMMMWx'............':cokOOXXOxONWMNOod0WMMMMMWXkdOKNWXxldKX    //
//    cc;';ldkKWMMMMMMMMMMW0dl,.......';,c0WWMMMW0OKNMW0olkNMMMMMMMKoxKWWXx;.:kKK    //
//    ..',:l0XkONMMMMMMMMNkldkOkdddodol;',okOKX0k0NXkxl:dNMMMMMMMMMXOOOkxl''cxKWM    //
//    .,lk0kkKNOkNMMMMMMXxok00NMMMMMMWOc,,:lc;,,:kKo'':oOWMMMMNWMMNkdxkko;:kNWMMM    //
//    ,:0WMNOxOXOxXMWKkxlcxKWMMMMMMMWOxo,;llc,..;:;,';oddXMMMW0KWXOO0Kkc;dXMMMMMM    //
//    :;c0WWK0kkK0xkdlc::dXMMMMWXXWM0:,;,ldl;,;:::;:;:0XokWMMMWNNKkdl;,lOWMMMMMNO    //
//    ''.;OWWNOxxOkl;,,:doxNMMMWkcONk:,,'cc,'.,lxKNXo'dNxoXMMWNXNO:.':kNMMMMMNOdd    //
//    '...:KNNKdlolokkdoOOcxNMMMXxOOlo0xcxxl::xNMWXx:,cXKodNMXOOd,',oKWMMMMMXdcc:    //
//    ;lo;,xXNW0oddollxXKo,,kWMM0oxxkNWO:lkO0NWNOdolkklkNOlodc:;',ckNMMMMMMWOl;.'    //
//    NMMKcl0OKNkc;,'lKO:;ddkNMNd,ckNNxlxKWMMNOocdkc;l:;xx:lo:.'':kWMMMMMWOx0d,cO    //
//    MMMWkl0NNOlxkc,ox::OWMMMMXl;dXMO;oXMNX0xd0kl:;'',',,cOk:.'cONMMMMMMKcok:cKM    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract DISK is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
