
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neverland
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//      _   _   ______  __      __  ______   _____    _                   _   _   _____                       //
//     | \ | | |  ____| \ \    / / |  ____| |  __ \  | |          /\     | \ | | |  __ \                      //
//     |  \| | | |__     \ \  / /  | |__    | |__) | | |         /  \    |  \| | | |  | |                     //
//     | . ` | |  __|     \ \/ /   |  __|   |  _  /  | |        / /\ \   | . ` | | |  | |                     //
//     | |\  | | |____     \  /    | |____  | | \ \  | |____   / ____ \  | |\  | | |__| |                     //
//     |_| \_| |______|     \/     |______| |_|  \_\ |______| /_/    \_\ |_| \_| |_____/                      //
//                                                                                                            //
//                                                                                                            //
//    '''',,;;;;;,,;;;;;:::::;;;;;:::cccc::::::::ccccc:::::::::ccc::::::::::::::;;;;;;;;;;;;;;;;,,,,,,,,,,    //
//    ''',,,;;;;;;,,,;;;:::::;;;;::::cccc::::::::cccccc:c:::::ccccc:::::::::cc::::;;;;;;;;;;;;;;,,,'',,,,,    //
//    ,,,,,;;;;;;;;;;;;::::::;;;;::::ccccc::::::cccccccccccccccccccc::::::::ccc::::;;;;;;;;;::;;,,,,,,,,,,    //
//    ,,,,,;;;;;;;;;;;;::c::::::::::ccccccccc::;;;;;;;;;;;;;;,,;:cccc::::::cccc:::::;:;;;;;:::;;,,,,,,,;;,    //
//    ,,,,;;;::;;;;;;;;:cc::::::::::ccccc:;,;:ccllooddddxxxddllcc:;,,;:c::cccccc:::::::;;::::::;;,,,,,,;;;    //
//    ,,,;;;:::;;;;;:::::ccc:::::::cccc;;:coxOOOOOOOOOOOO0000000OOxol:;',:cccccc:::::::::::::::;;;;;,,;;;;    //
//    ,,,;;;::::;;;;::::cccc::::::c:;;:cdkOOO000000000000000000000OOOOko:;,,:ccc:::::::::::::::;;;;;;;;;;;    //
//    ,;;;;:::::;;::::::cccc:::::;,,:okOO0000OOOOOOOkkkkkkkkOOOOOO00000OOkdc,,;cc::::::::::c::::;;;;;;;;;;    //
//    ;;;;;::::::::;::::cccccc:,,:lxOOO00OOkxolc:::;;;;;;;;;;::cloxOOOO00OOOko;,:c::::::::ccc:::;;;;;;;;;;    //
//    ;;;;:::::::::::::cccccc;,:dkOO00OOxl:;,,',,;;;;;:;;;;;;,,,,,,,:lxOOO00OOkl,,:::::cccccc::::;;;;;;:::    //
//    ;;;;:::::c:::::::ccccc,,okOO0OOko;,',;;:;;;:::::::::::::::::;,''';lkOOO0OOx:';::::ccccccc:::;::;::::    //
//    ;;;;::::cc::::::cccc:,:dkO0OOkl,',;;;::::::::ccccccccccc::::::::;'.,cxOOOOOko,,:c::ccccccc::::::::::    //
//    ;;;::::cccc:::ccccl:,lkOO0Okl;',;;;:::cccccclllllllllllllllcccc::::,.'cxOO0OOx:';ccccccccc::::::::c:    //
//    ;;:::cccccc:::cccc;,oOO00Od;',;;:::ccclllllool;............,cllccc:::,.,lkO0OOkc';cccccccc::::::::::    //
//    :::::cccccc::::cc;,dOO0OOl'';;:::cclllooooddo'              ;ooollcc::;'.ckO00OOl';ccclccc:::::::ccc    //
//    :::::cccccc:::cc;,oOO0OOl',;;::cclloooddddxx:               ;dddoollcc::,.;xOO0OOc':llllcc:::::::cc:    //
//    :::::cccccc::cc:,lOO0OOd'';::ccllooodddxxxko.               :xxdddoolcc::,.,xO00Ox;,cllllc:::::::cc:    //
//    :::::cccccccccc,ckOO0Od,';::ccloolc::::::::,                ckxxxddoolcc::,.;kO0OOd,;lllcccc::::cccc    //
//    :::::ccccccccc:,oOO0Od,';::ccllol.                          .;;:coodoolcc:;'.lOO0OO:'cllcccccc:ccccc    //
//    :::::ccccccccc,;xO0Ok:.,::ccloodoc:cloooool;.................     .',:clc::,.:kO0OOo,:llcccccccccccc    //
//    ::::ccccccccc:'lOO0Od'';::cllodddxxxxxxkkkx'            ...:dolc:,'...;lc::;.;kO0OOx;;lllcccc::ccccc    //
//    ::::ccclllccc;,dOO0Oc.,;:cclodxxxxxxxxkkkkd.               :kkxxxxxdlllllc::''oO00Ok;,llllcccccccccc    //
//    ::::ccccccccc,;xOO0k,.;;:cloxOOxxxxxxkkkkko.              .dkkxxxxxxddollc::,.cO00Ok;,lllccccccccccc    //
//    :::ccccccccc:'cOO00x,.;;:cldOKOxxxxxxkkkkkc               :kkkxxxxxxddoolc::,.cOO0Ok;,llcccccc::cccc    //
//    ::::cccccccc:'cOO0Od'';::clox000Okxxxkkkkk:              .dkkkxxxxxxddoolc::,.cOO0Ok;,llcccccc::cccc    //
//    ::::ccclcccc:'lOO0Ol.';::clx0KXXKkxxxkkkkx,              :kkkkxxxxxxddoolc::'.oOO00x,;lllccccccccccc    //
//    :::ccclllccc;'oOO0Ol.';;:clxXWN0kxxxxkkkkx'             .dkkkxxxxxxxddollc::',xO0O0o,:ollccccccccccc    //
//    :::ccccccccc:'lOO0Ol.';;:cloxKX0kxxxxkkkkd.             :kkkkxxxxxxddoolcc:;.;kO0OOl'clllccccccccccc    //
//    ::::cccccccc:':kO0Oo'.;;:cllodkOkxxxkxocc;.            'dkkkxxxxxxxddoolc::;.:kO0Ok;,llllcccccc:cccc    //
//    ::::ccccccccc,;xO0Ox;.,;::clooolccdxl,':dl.           .okkkxxxxxxxdddollc::''dO0OOd';lllcccccccccccc    //
//    :::::cccccccc:,oOOOOl.';;:cll,.   ....okko.          .okkkxxxxxxxxddoolcc:;.:kO0OOc':lllcccccccccccc    //
//    :::::ccccccccc,:kO0Ox;.,;::cl'      ;dkxko.        .;dkkxxkxxxxxxdddollc::,'oOOOOx,,llllcccc:ccccccc    //
//    :::::ccccccccc;,d00OOo'.;;:clc;'.';lxxxkkx:.....,codkxl;'cxxxxxxxddoolcc::.,x0OOOc':llllccc:::::ccc:    //
//    :::::cccccccccc,:k00Okl.';::clooddxxxxxkkkkxollooc:;'.   'dkxxxxddoollc::,'lO0OOd,;ccllccccc::::cccc    //
//    :::::cccccccccc:'cOO0Okc.';::clooddxxxxxkkkk:..          .lxxxxxddoolc::;'ckOOOx;,ccccccccc::::::ccc    //
//    :::::cccccc:cccc:,lOO0Ok:.';::clooddxxxxxxkx,        ......':ldxdoollc:;':kOOOx:,:cccccccc::::::::::    //
//    ;:::::cccc::::::c:;oOO0Oxc.';::cllooddxxxdoc'..  ......       .':cllcc;'ck0OOx;,:ccccccccc::::::::::    //
//    ;;;;::cccc::::::ccc;cxO0Oko,.';::clllc;,'..                       .';,,lk0OOx;,:ccccccccc:::::::::::    //
//    ;;;;:::cc::::::::ccc,;dOO0Oxl,.,:;,..                               .:dOOOOd,,:c:::cccccc::::;;:::::    //
//    ;;;;::::::::::::::ccc;,lkO0Okxc,..                                .;okOOOko,,:cc::::ccccc:::;;;;;;::    //
//    ;;;;;::::::::;::::cccc;';dOOOOkxl;.                             'cdOOOOOxc,;ccc:::::::ccc::;;;;;;;::    //
//    ;;;;;;:::::;;;::::cccc::,,:dkOOOOkxl,.                       .;lkOOOOOxc,;:cc:::::::::cc::;;;;;;;;:;    //
//    ,,,;;;::::;;;;;:::cccc::::,,:ldkOOOOkxoc;'..           ..',coxOOOOOkdc;;:cc::::::::::::::;;;;;;;;;;;    //
//    ,,,;;;:::::;;;;;::cccc:::::::;;:coxOOOOOOOkxoc::::::clodxkOOOOOOOxl:,;ccccc:::::::::::::::;;;;;,;;;;    //
//    ,,,;;;:::;;;;;;;:::::::::::::ccc:;;:codkOOOOOOOOOOOOOOOOOOOOOkdlc;,;cccccc:::::::::::::::;;;;;,,,;;;    //
//    ,,,,;;;;;;;;;;;;;:::::::::::::ccccc:;,;:::cldxxkkkkkkkxdollc:;;;;cc:cccccc::::::::;;::::;;,,,,,,,;;;    //
//    ,,,,;;;;;;;;;;;;;:::::::::::::cccccc:cc::;,,;;;:::;:::;;;;;;:cc:::::cccccc::::;;;;;::::;;;,,,,,,,,,,    //
//    ,,,,,;;;;;;;,;;;;;::::::::::::cccccc:::::::cccccc:cc::ccccccccc::::::cccc:::;;;;;;;;;:;;;,,,,,,,,,,,    //
//    ',,,,;;;;;,,;;;;;::::::::::::::cccc::::::::ccccc:::::::cccccccc::::::cc::::;;;;;;;;;;;;;;,,,,,,,,,,,    //
//    '',,,,;;;;;,,;;;;;::::::;;;:::::ccc::::::::ccccc::::::::cccccc:::::::cc::::;;;;;;;;;;;;;;,,,,,,',,,,    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NVRLND is ERC721Creator {
    constructor() ERC721Creator("Neverland", "NVRLND") {}
}
