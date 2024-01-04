// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Greater Fool
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ,;,,,;cc;,,,,,,,;;;;;;:ldxxxxxkkOOOkkkkxo:,,;:;;;;;,,;clooooddocloodxxkko:::;;;::::;;,,,,,;;;;,,,,,,    //
//    ;;,;,;odl;,,,,,;;;;;;;;:lxxxxkOOOOOOkxo;'...,;;;;;;,,;:cccloddc,,;::clxkdc:;,,;::::;;;,,,;;;;:;;,,,,    //
//    ;,,,,,cxxdlc;,,,;;;;;;;:coxxk0Okxolc:;'.......',,''........',;::cloddc:doc::;;;;:ccc:;;;;;,;;;::::::    //
//    ;;:;;;:oxkkxo:;;::::;;;;:cok0Odc:c;;;,'.,:loooooooodxxkkxdl;'.'',;:cldc;:::;;::cooc::;;:::::;;,,;;;;    //
//    :::::::cdkkkkdc;::::::c::cdOkl,,:ol:,,:d0XWWWWWWMMMMMMMMMMWN0o;'',,,:ol;:lccc::cllcccccc::::;;;,,;;,    //
//    :::;;;;;lxkkkkdlc::::ccccokk:,,.',,,:dKNNNWWWWWWWMMMMMMMMMMMMW0l,',,,;,';::::cccccccllllllcc:;;;,,,,    //
//    c:;:::::lxkkkkkolcccllllok0l';;....:kXNNNNWWWWWWWMMMMMMMMMMWWWWXk:'',co;',;',:ccoddxxkkkkxxdl:,,,,,,    //
//    :;,,;;:cokkkkkxocc:ccloxO0d,..,'..;xKXNNNWWWWWWWWWWWWWWWWWWWWWWWN0:.',lc;,:c;,lxkOOOOOkxollcc::;,,;;    //
//    ;;;,;;;cdkkkkkkdl::::lx00x,.,;,..'cx0KXNNNWWWWWWWWWWWWWWWWWWWWWWWNx,.'',;::coc:okOOOOkoc:;;;;;;;;;:c    //
//    ;:cc:::okOkkOOxoc:::lk000k;.,;;..;lxO0KXNNNWWWWWWWWWNNNNWWWWWWWWWNk;';:ldd:.,;:cxOOOxlc::::::;;;;;:c    //
//    ::cc::okOOOOOkdccllok00000x;.....:dxxolc:lONWWWWNKkxoc:ccldk0NWWWKo'',;clc:;'':xOOOdc;;;;:clcccccccc    //
//    cllc:lkOOOOOOxlcclok000000x;... .:c;'.....;xXWWNNKkxddolllllco0NNXo......;kx:;,lOOkdlcccccclc:ccccc:    //
//    lllclxO0OOO0kolcclxO000000k;..  .;,;;,,,,,;;dXWNXOkxoc::ccodkxOXWNd'.....,c;.';o0Odlclloolllc:;;;;;;    //
//    ccccxO00000OdccccoO0000000Ox:...,cc;'''',,',lKNNKkkxocc:::cldOKNNNx'....;:,,,,.l00xlllllllcc:;,,,;:c    //
//    ooldO000000koc::lx000000000kl,:::do:;:;,cc;cONNXKKXKOkx;',,ldx0NNNx;..'cllc'';ckKKOdooollclcc:cccccc    //
//    lclxO000000OdlcldO000000000Oxc;;cxkkxxxdocxNWWWNXXXXK0kdodkOOOKXNNd,'.;oxdl:lO0KKK0kddooloddc::clllc    //
//    :cok00000000OkkkO0000000OOOOOxc;o0XX0kdl:;xXNWWWWNXKOkkkOKXNWWNNNNk::colxXdck000000kdoddddkOxl::ccc:    //
//    cclx00O0000000000000000OOOOOOk:;odocc:::;,;coddoxO0OxxxddddkXWWMWNXKkk0Oklcx0000000koclllox0Kkoolllc    //
//    ::ldOOOOOOOO0000000OOOOOOOOOOOo;:;',,;;:clllodxkO0KKKK0Okdc,;ok0OO00KKkocok00000000kdoooodOKK0dcccll    //
//    ;cloxOOOOOOOOOOOOOOOOOOOOOOOOOOd:;:::,'cddooxdxkxO0OkOOkkx:.':coxOOlllcokO000000000xoldxk0KKK0d:;;;:    //
//    :cccokOOOOOOOOOOOOOOOOOOO000KKKKOl:cdc'';c:oklokookocc::;'.'dOO0XKl:dkOOOOO00000000kddkO00000Od:;:::    //
//    ;codddkOOOOOOOOOOOOOO00KKXXXXXXXXKklclc,.  ..  .         .,xXXXXOlo0KKK00OOOO0000000000000000kdllcc:    //
//    :clllokOOOOOOOOOOO0KKXXXXXXXXXXXKK0Ooclll;':;'''....,;,.,ckXN0xolxKXXXXXKK00OO00000000000000koc::cll    //
//    cclccdOOOOOOOOO0KXXXXXXXXXKK00OOOkOOOdllollxxxO0OkkkOOdod0N0ocldOKKXXXXXXXXXKK000000OOOOOO0Oxolc:ldo    //
//    ;:coxOOOOOOOO0KXXXXXXXXK0OOkkkO000KXXKOddoloodxkkkkkxxxO0kl:lkOOOOO00KKXXXXXXXXK00OOOOOOOO0Oxddoloxd    //
//    :coxOOOOkxdk0KKXXXXKK0OkkkkkOKKK00KNNNN0kkOOOOOOOOOOO00kc;o0XXXXK0OOOOO00KXXXXXXXK0OOOOOO00kolloodkk    //
//    cokkkOkxxk0KK00KXK0OkkO0KXK00KXK0OOXNNNNOlkXNNWWWMMWXkl:;cx0XXXXXX0OO0OOOO0KXXXXXXXK0OOOO00koc::cokk    //
//    dxkxxxxOKX0xdxOOOkkO0KXXXXXXKKXXX0O0XNNXkc:oxOO00kxdoloxdOk:lkKXXXKKKXKK0OOOO0KXXXXXXK0OOOOOxl:::lxk    //
//    dkkddOXKxoodddxkxxkOKXXXXXXXXKXXNX0O0NWKkOl;;:ccodxk0K0O0NO,:olxKXXXXXXXK0OOkOO0KXXXXXK0OOOOkdc::lxk    //
//    KX0xokkookOXNNkdkxOK0KXXXXXXXXXNNNXK0K0odNXdlox0XNNXKKKXWMO,:kxccxKXXXXXKOOOOkkOO0KXXXXXK0OOOOxolokk    //
//    Oxc::ldldXXOkKNkxkk0XKKXXXXXXXXNNNNKd;..lNMWOdk0OO0KXNWMMMk;lkkk;.':ok0KKOOO00OkkOOKXXXXXK0OOOOkkkkk    //
//    odxxdlcllx0000KXOdxx0XXXXXXXXXXNNKd;....,lk0xldkdkKXNWMMMWo,dOood'..',:clodk000OkkkO0KXXXKK0Okkkkkkk    //
//    dkOXN0o:cco0Xklclldkk0XXXXXXXKOdc,....  ...'.lXO:;;;,cKMWk;cOkl;l:..';ldol:;clccxkkkk0KKKKKK0Okkkkkk    //
//    cxO0XKl';c:okc...;oxxk0KXXXkc,...............'c, .....;do,,xOkc,,cc'.:kOd::dOko,cOOkkkOKKKKKK0Okkkkk    //
//    ';cxOx;..;;:ll:;cxXkdkOKKX0; ..... .'....    .      .''.  :O0Oo;..',;dOc.,odoc:,:O0OkkkOKKKKKK0kkkkk    //
//    :;,,coc..;::;cx0NMW0odkOKKx.  ....,,'. ...  ...     .... .o00OOOko:;:o:.'cc;,,;'l000OkkkOKKKKKKOkxxx    //
//    0kl;',::okxl;;cdO0KKOlokOKx.  ....,:,.. ..  'lc.    ...  'kOooxOkc..cc. .cdkkx::kK000Okkk0KKKKK0Oxxx    //
//    KKKOo:'';oOkl;;:ldkOd::xxOd.  ... .:lc. ...;oxkd'   ...  :OOocod,  ,l'  ..'cdkcl0KKKK0OkkO0KKKKK0kxx    //
//    KKKK0kl:,';cl;,;:cc;;;,lxx:.   .. .:xo'.':kOOxkKOc,.... .lOOkxd,  .o:. .....':;;kKKKKKOkkkOKKKKK0Oxx    //
//    KKKK0kkkxo:,,,',::cl:;;cxkl.   .. .;xo.',cOOOOxkXOo;.,. .lkkOk;   ;c. .';c:;'',,lKKKKK0kkkk0KKKKKOkx    //
//    KKKKOkkk0K0xc;;;clccodoxkkxl'  .. .,xl..;;dOkOkOkc;;,'. .cxkk:  .,lo. ...;oxxoc,oKKKKK0OkkkOKKKK00kx    //
//    KKK0kkkOKXXXKxc;:cl:;ldxdddoccoo' .,xl..;::oOXOdllxdc'. .cxkc. 'ccoc.   ...;okklckKKKKKOkkkO0KK000kl    //
//    KKK0kkkOKXXXXXKxc::l:,;ooclkKKkl;..;xc  .:c:ldccodooc'..'cxl...,:;,.     ...';ldl:d0KKK0kkkO0KK000ko    //
//    KKK0kkkOKXXXXXXXKx:;cc,,;cOXkcl0XO:;o: .;;cdo:lolccc;'..'ld'   ..''.   ........',,;ckKK0kkkO0K0000kd    //
//    KKK0kkkO0KKKKKX0xxo;,c:';O0o:dXN0Oo;l, .;clxOdxOkdoo:'..'lc.    .''.   ..',;;;,..'::cOK0kkkO000000kd    //
//    KKK0kkkk0KKKK0kdx0K0xl;:k0ocOXOxOOc;o' .;:lxx::llccc:'..'l;     .''. ..  ..,;c:,;dxlo00OkkkO000000ko    //
//    00K0OkxkOKKOxooxxxddxo:oOOOXKxdKN0::l. .',cxdldkdoll;'..'c' .    .'. .:.   ....,okOdokOOkxkO000000xl    //
//    0000Okxxk0OddkOkkkkd:..codOK00X0O0c;c. .;:lkxooxdll:,'..':. ..    .. .ld'  ...'lc;col:cldxk000000Odl    //
//    00000kxxkO0KKKKKKKKK0:..,;cxKNXKNk,:;  .',:dl,:loll:,'. .;. ..        :0k,  ...:l;,'':l:cxO000000kdo    //
//    00000OkxxkO0KKKKKKKKKO, .,;cldkKO;.c,  .',cxlcxOdll:,.. .,. ..        'k0:   . .'...;dxclkO000000koo    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Fool is ERC721Creator {
    constructor() ERC721Creator("The Greater Fool", "Fool") {}
}
