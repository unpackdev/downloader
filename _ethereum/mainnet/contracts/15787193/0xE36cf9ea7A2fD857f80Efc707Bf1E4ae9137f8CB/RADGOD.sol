
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RadGods
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkxxxxxxxxdddxxxxxxxkkkkkxddoollc:cclllolc;,',;cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdol:,........................................''''....,lkNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0d:'..........................''''''''''....'''''''''''''..';o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXxc,...........................'''''''..'''''''''''''''''''''''..':dONWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNx;.......................................'''''''''''''''....''''.....':loxOXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0c'......................................''''''''''''''''''''''''''''''''''',:lxKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWk;............................'''''.....'''''''''''''''''',,,,''''''''''''''''''';kWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXo'.................'''''..''..'''''''..'''''''''''''''''''''''',''''''''''''''',',';dXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0:................'''''''''''''''''''''''''''''''''''''''''''''''''''''''',''''''''''',cONMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMK:............'..''''''''''''..'''''''''''''''''''''''''''''''''''''''''''',,'''''''''''',cONMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKc............'''''''''''''...''''''''''''''''''''''''''''''''''....'''''''''''''''''''''''',l0WMMMMMMMMMM    //
//    MMMMMMMMMMMMW0c............'''''''''''.....''''''''''''....''''''''''''''''''.....''''''''''''''''''''','''';o0WMMMMMMMM    //
//    MMMMMMMMMMMWO;............'''''''''......'''''''''''''.....'','''''''..'''''''.....''''''''''''''''''''''''''':OWMMMMMMM    //
//    MMMMMMMMMMMK:..'........''''''.........'''',,'''''''''....'',,''''''....'''''''....'''''''''''''''''''''''''''':OWMMMMMM    //
//    MMMMMMMMMMXc..'......'''''''''.......'''''''''''''''''....',,,''''''......''''''...''''''''''''''''''''..''''',':OWMMMMM    //
//    MMMMMMMMMNd'.''....''''''''''.......''''''''''''''''''...'',,''''''':dd;...'''''...'''',''.'''''..'''''..'''''','cKMMMMM    //
//    MMMMMMMMMO,.''.....'''''''''.....'''''''''''''''..''''...''''''''',cOKKx,...''''...'''''''..','''...''...'''''''',lKWMMM    //
//    MMMMMMMMXl.''.....''''''''''....'''''..''''''''....'''...''''''.',lOKKK0d,...'''...'''''''..''','....'..'','''''''':kWMM    //
//    MMMMMMMWx'.''....''''''''''...''''''...''''''''...''''..''''''.',lOKKKKK0d,...'''...''''''...'''....''..'''''''''',';xNM    //
//    MMMMMMMk,.''....''''''''''....'''''.....''''''....''''..'''''..'lOKKKKKKK0d,...''...'''''.''..''.'oc'...''''''''''',',dN    //
//    MMMMMMKc.''....''''''''''....''''''..'..'''''....''''..'''''...:OKKKKKKKKK0d,.......'''''..''...,o0o...'''''....'''',',x    //
//    MMMMMXl.'''....''''''''''....'''''.'lo,.'''''...'''''..''''...,xKKKKKKKKKKK0xc;'.'::''''...'',cdOKKxl,.''''..','.''''',x    //
//    MMMMWd'.''.....'''''.'''....''''''.:OO;.''''.....'''','''''...l0KKKKKKKKKKKKKKOd:lOd,''....':x0KKKKKO:.''..'lkOx;.'''.lX    //
//    MMMWk,.'''.....'''''..'.....'''''.'dK0l.'''...,cc;,,co:'''...:OKKKKKKKKKKKKKKKKK00Kk;.'...,lkKKKKKKKO;.'',codl:;'....;OM    //
//    MMM0;.''''.....''''.........'''''.;OKKd'.'...,dKKOkO0Kx,.'.,:xKKKKKKKKKKKKKKKKKKKKKOc....;o0KKKKKKK0x;......     ..'cOWM    //
//    MMM0;.'''''.....'''.........''''''l0K0Oc....;x0KKKKKKKO:.'.;okKKKKKKKKKKKKKKKKKKKKK0o..':xKK0kxol:,..           .:o0NMMM    //
//    MMMXc.''''''.....''..... .....''.,xKx;''...'lkO00KKKKK0l...ck0KKKKKKKKKKKKKKKKKKKKKKOoccll:,..         ....,;:ccxXWMMMMM    //
//    MMMNo..'''''......'..      ......:OKl    .. ..:clo;;:cc;...lOO00KKKKKKKKKKKKKKKKKKK0o'..      ........,:dkO000K00NMMMMMM    //
//    MMMMK:.''''''. ......       'oo;'c0Kklllcc::;,:clc.        ....,;:clodk00KKKKKKKKKKKd;',;:l:.....       .ck000000NMMMMMM    //
//    MMMMM0:.'''''.. .....       ;OK0kk0KKKKKKKKKKK000Okdolcccc::;;,''......'lOKKKKKKKKK000000KO;   ...        ;k00000NMMMMMM    //
//    MMMMMMKc.''''..  .....      ,OKKKKKKKKKKKKKKKKKKKKKKKKK000KKKKK000Okxdold0KKKKKKKKK000000k;    cKd.        'x0000XMMMMMM    //
//    MMMMMMM0c'''''.    ...      .xKKKKKKKKKKKKKKK00Okdoc:;'..':k0KKKKKKKKKKKKKKKKKKKKK000000k,     .,'   .      ;O00OXMMMMMM    //
//    MMMMMMMMNOc'''..            .lKKKKKKKKKKK0dc;'......       .'cOKKKKKKKKKKKKKKKKKKK0OOO00c        .'.    ..  :O000NMMMMMM    //
//    MMMMMMMMMMKc'''.             ,kKKKKKKKKKO:     .o0K:          .oOKKKKKKKKKKKKKKKKK0OOO0O:  ..   .l:    .'..,d000XWMMMMMM    //
//    MMMMMMMMMMWx,''.             .lKKKKKKKKk,       'lo'            ,dKKKKKKKKKKKKKKKK0OOO00:  ..   ...    ...dkk000NMMMMMMM    //
//    MMMMMMMMMMMK:''.   ..',,;,.   ,OK0KKKOl.    ..        '.         .l0KKKKKKKKKKKKK00O0000o. .,.        .'.:OOO000NMMMMMMM    //
//    MMMMMMMMMMMXc.'. .:dOO0000o.  .dK000k,   .  .,.      .;.      '.  .xKKKKKKKKKKKKK00O0000O, .;'.     .,'..d0O000kONMMMMMM    //
//    MMMMMMMMMMMO;.'..l0K000KKKKk:. ;OK0d'. .o0; .;,.      .      .;'  'kKKKKKKKKKKKKKK0O00000l..',,'''..'l,.c00O00Oc;kWMMMMM    //
//    MMMMMMMMMMNo'''.:OK0KKKKKKKK0d;ckK0OxxdldN0, .;,.            .'.  ;OKKKKK00KKKKKK00OOO000k' ..',;;;,...cO00000x;,:kNMMMM    //
//    MMMMMMMMMMO;.'',xKKKKKKKKKKKKK0KK00000K0O0W0,.';;.        .,;.    ;0KKKK0000KKKK000OOOO000l    ...... ,kOO0000o,,,;dNMMM    //
//    MMMMMMMMMNo'''',xKKKKKKKKKKKKKK0000000KKKKXWK; .,:;'......:0Kl    :0KKKKK000KK000000OOOOO0koccllll:;';dOO0000k:,,,,;dNMM    //
//    MMMMMMMMM0;.''''o0KKKKKKKKKKKKK0000000KKKKKKNKo,..',;;;::'...     cKKKKKKKKKKKKKKKKK00OOOO0000OOOOOOOOOOO000Ol,,,,,,;dNM    //
//    MMMMMMMMNd'''''';x0000000KKKKKK00000000KKKKKKKXKx,  ......        lKKKKKKKKKKKKKKXXXXK0OOOOOOOOOOOOOOOOOO000d;,,,,,,,;kW    //
//    MMMMMMMNx,''''''';x00000000000000000000KKKKKKK00d,  ...',:cclcc::ckKKKKKKKKKKKKKKKXXKK0000OOOOOOOOOOOOOO000x:,,',,,,,,c0    //
//    MMMMMMWx,''''''''';lddxxkkO0000000000000KKKKKKKKKOdxkO00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000OOOOOOOOOOO00x:,,,'',,,,,,o    //
//    MMMMMWO;''''''''''''''',,,;ccoxkO000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000OOOOOOOO00Od;,,,,'.'',,,,:    //
//    MMMMWO:''''''''''''''''''.....',:okO000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKK000Okkxddolllk000000OOOOOOO0Od:,,,,,'',lxkkkkk    //
//    MMWXd;'''''..'''''''''''''''''''.';lxO0O00000000KKKKKKKKKKKKKKKKKKKKKKKKKOc.....      'kK0000OOOOOO0Odc,',,'',,';0MMMMMM    //
//    Xko:,'''.',,.'''''''''''''''''''''..':okO0O0000000K0KKKKKKKKKKKKKKK0000KK0l......'',,:xK0000OOOOOOkoc,,,,,,,,''',xWMMMMM    //
//    o::;,,'';dK0c'''''''''''''''''''''''..',coxO0000000000KKKKKKKKKKK000000KKK0kkkOO000KKK0000OOOOOOkl;,,,,,,''',,',';dXWMMM    //
//    NNXXK000XWMWx,'''''''''''''''.'''''''''...,dKK0000000000000000000000000000000000K0000000OOOOOOxl;,,,,,,,,''.'',,,',:dxkN    //
//    MMMMMMMMMMMM0:'''''.''''.'''''...'''''''.'oXWWNNXKK000000000000000000000000000000000000OOkdol:,',,''''',,,'',,'',,,'';kN    //
//    MMMMMMMMMMMMWo'''''..'''..''''';,'.'''''.:KMMMMMMMWWNXKK0000000000000000000OO0000000Okdoc;,'''''''',co:',';xKKkl,',cxKWM    //
//    MMMMMMMMMMMMMk,.'''''''...'''.;kXOo:'.''.:KMMMMMMMMMMMMWWNNXXXXXXKKKK00000OOO000KOdlc:,,''',,,,;cokKNWk,;l0WMMMN0kONMMMM    //
//    MMMMMMMMMMMMM0;.''od,''...'''''kMMMN0d;'.'dNMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNNNWWWWKKKKKK000KKKKNWMMMMMNKKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNl.'dNO,''...'',',kMMMMMWXkl,'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWx;dNM0:;ldo,.'',oXMMMMMMMMWKkkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXKNMMWXXWMNd,,cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXddNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RADGOD is ERC721Creator {
    constructor() ERC721Creator("RadGods", "RADGOD") {}
}
