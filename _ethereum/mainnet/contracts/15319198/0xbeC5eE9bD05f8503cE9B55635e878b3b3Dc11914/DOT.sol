
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: .
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXKOO0KK0Okxx0XKO0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWWWWNNXK0kdollclllcclollllllxO0000KNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXNNXKkddolcccl:;;;;;;;;;;;;;;;;;::::clxO0KXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNKkl:;;;;;;;;;,,,,;;;,,,,,,,,;;;;;;;:clcclokXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXOxdol:,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;::cdKK0XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKkxo:;;;;,,cl,'''''''''''''''''''''''',,''',,,,,;;;:cloxOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOl:;;;;,,,,',,'''''''''...''''''''''''''''..''''',,,;;;:ccokXWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWNXKxc;;;;,,,''''''''''''''............'..''''...''''''',,;;;;;::okOKWK0XWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWKxoc;;,,,,,,'''''''''''...........................'''''''',,,,,,;;;:oOOOXWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWNXOl:;;,,,,'''''''''''''...............................''''''''''',,,;;;;oXWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWNK0o;;,,,'''..............................................''''''''''''',,,,lKWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWKdl:,,,'''.........................................................'.'''',,;xXKNWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWN0l;,,,''...............................................................''',,lOKNWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNXk:,,,''..................................................................''''':x0XWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNkl;,,''......................................................................'''',lxOKNWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWXo,,'''.................................................         .................',cONWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW0c,,'''..................    ........            .....             ..............'''c0WWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWXXXd;,''''.........                                                     ..............',oKNWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWXOo:,'''...........                                                      .. ............,dXWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWO:','''............                                                           ..........cKWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWNKx:''..............                                                            ..........cKWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWNKx:''...........                                                               ..........;OWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNk;'...........                                                                      ... 'OWWNWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWKl'...........                                                                       ...cKWWNWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWXXKc............                                                                       ...;0WWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWNNW0;....  ......                                                                       ...cKWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWNNWK:...........                                                                        ..,xNWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWXo,........                                                                          .;d0NWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWNKd'.........                                                                        .:0WWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW0:........                                                                         .:0WWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNx,......                                                                         .,kNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNKk:.:;.                                                                         .'dXWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNkl;..                                                                         .;kNWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNX0x;.                                                                       .;cxNWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWNXKKk:.                                                                    .cxkKNWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNXNNO:....                                                             ...l0KKKXWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNNWN0xo:.                                                              .,xKKKNWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNNNNXx:.                                                          .;dKWNNNWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx,.                                                       'dXWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKkl'.                                                .,lx0WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNX0o'.                                         ...:xKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKOxo:.                                   .;xOOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWN0o;;:;,.                     ....;ok0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNX0xc;codl:;;;;,;::;;coxkkOKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNWWWWWNNNNNNWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOT is ERC721Creator {
    constructor() ERC721Creator(".", "DOT") {}
}
