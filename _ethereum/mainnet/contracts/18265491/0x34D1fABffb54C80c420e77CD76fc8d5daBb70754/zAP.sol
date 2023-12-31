// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Attraction Paradox
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    .;clc;,;:ldkkkkkkKNMWWdlc::xWNWWNNWWNNXK00kxdlc::::::;,,'.,lxOd:,'.... ..    //
//    .,,;lllc:codxxxdxOXNWWMMMMMMMMMMWWMMMWNNX0OOOOOkxxxol:;,,cxkx:'..            //
//    .',;:lodddxxkkkkkO0KNWWMMMMMMMMMWMMMMMWWWWWWNNNK0OOkdolc:cc:,.               //
//    ..';lodxkOKXKKKK00KXNWMMMMMMMMMMMMMMMMMMMMMWWWNNX0OOkxkxxo:'..               //
//    .',:loodx0XNXXXXKXNWWMMMMMMMMMMMMMMMMMMMMMMMWWWNNKOkxxxxkxl:,'......         //
//    ;cloddxk0XWWNNNXXNWWMMMMMMMMMMMMMWWNNNWWMMMMMMMMWXKK0Okkkkdlc:;;:;'..        //
//    .'';cldkKNMWNNNNNWMMMMMMMMMWKOdlc:;;,,,;:ldOXWMMMWWNXKOkxxoccodol;'..        //
//    .....',:oONWWWWWWMMMMMMMNOdlccloooddol:;'...'cxXWMMMWWNKOxoccoddoc:,...      //
//    .     ..,o0WMMMMMMMMMWKo;;lkXWMMMWWWWWNKOdc,....l0WMMMMWNKOkkxdxxol;'.       //
//    .      .;dKWMMMMMMMMXo..cOKNWMMMMMMMMMMWNXKOdl;. .lKMMMMWN0Okxxxdoo:....     //
//         ...;o0NMMMMMMMK:.'xNWWMMMMMMMMMMMMMMWNX0kdc.  ,OWMMMWKkddooc:c;,,;:     //
//        .''.,lONMMMMMM0; .oXMMMMMMMMMMMMMMMMMMWWNXKkl'  'OWMMMWXOxolllc,..''     //
//       ....'ckKNWWMMMXc  .cKMMMMMMMMMMMMMMMMMMMMMMWXxc,. ;KMMMMWN0Okxxo:....     //
//         .';:okKWMMMWx.  .l0WMMMMMMMMMMMMMMMMMMMMMMWKkl,..xWMMMMWXK0koc,,,',     //
//      ..':l:cdkKWMMMWo  .:dONMMMMMMMMMMMMMMMMMMMMMMMMWO;. cNMMMMMWXKx:,',::;     //
//      .';lc:okKNWWMMWx...:oONMMMMMMMMMMMMMMMMMMMMMMMMMKc. :XMMMMMWXOo:'.';:c     //
//     ..'ldoldkKXWMMMWx. .:oONMMMMMMMMMMMMMMMMMMMMMMMMMXl. lNMMMMMMNOo:'...,;     //
//     ..':loxkkOKWMMMMO,..';o0NWWMMMMMMMMMMMMMMMMMMMMMMXl .kMMMMMMMWKko;....'     //
//     .;cc:lxdlo0NMMMMW0lcc;,lOKXWMMMMMMMMMMMMMMMMMMMMW0,.cNMMMMMMMNKkdc'....     //
//    .;ll:,';cccd0NMMMMWOl:;';oOKNWMMMMMMMMMMMMMMMMMMNk,.cKMMMMMMMMN0kkxc'...     //
//     .','..';;,cxKWMMMMNx,...,lxkOKXNNWWWWMMMMMMMMMNx'.dNMMMMMMMMMWX0OOkl;..     //
//    ..,,,'.....;dOXNWMMMWO:. .'::clodOKNNWWWWMMMMWKd;cOWMMMMMMMMMMWNX0OOxl,.     //
//    ;,;;,,..  .:dOKNWWMMMMNk:......';cdO0KXXXKKOdolx0NMMMMMMMMMMMWWWNXK0Oo;'     //
//    c:::;'... .;cok0XNWWWWMMWKx:'.    ..',;;;;:ldONMMMMMMMMMMMMMWWNNNNNNKxc;     //
//    :llll:;;,''...;lx0XXXXNWWMMWN0kdolllloodk0XWMMMMMMMMMMMWNNNNWNXXXXXK0xc:     //
//    .;clc:;:;;;,....;oxxxxkOKXNWWWMMMMMMMMMMMMMMMMMMMMMMMMWNXK0KXK00OO00kdc;     //
//    ..;lol:;;'...',,':oollcloodxkO0KXNNWWWWMMMMMMMMMMMMMMWWNXK00000OOkOkxl:,     //
//    ...,cooc;,,'';:;';::::::::ccccldxOKXXNWWWWWWMMMMMMMMMWWNX00OOkxxxddooc;'     //
//    .''',,:llcccclol:c:;;;;;,,;;;:lxO00KKXXXXNWWWWMMMMMMMMWNKKKX0kxdooollc;.     //
//    .'''.....',,;:;;:;;,,,,''',,;:loxO0KXXKKXNWWWWWWWWWWMMMWNXNX0kxxdoolc:,.     //
//    .............. ................,:ldkO000KXXNNXKKXKXNWMMMMWWX0kxdolllc;'.     //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract zAP is ERC721Creator {
    constructor() ERC721Creator("Attraction Paradox", "zAP") {}
}
