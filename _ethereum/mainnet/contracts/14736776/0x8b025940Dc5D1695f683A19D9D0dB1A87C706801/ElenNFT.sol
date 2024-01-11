
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ElenNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOKX0XWWMMMMMK0NWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkoxc:xOKWMMMMk:lONWWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:,;.';cdXMMMMk'.;doxNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMXc.......'xWMMWx.....,d0WMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNMWK:.... '.  'kWMXl......':OWM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXKK0KWWk,.  .  ..   .kWO,...    .oXM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWNWKOOOXXd.    .  .. .'.,kl....    .;OM    //
//    MMMMMMMMMMMMMMWWWMMMMMMMMMMMWWWMMMN0O0NWMNXX0kk0Oc.     .   .  .'.''...      .oK    //
//    MMMMMMMMMMMMMMWNWMMMMWWMMMMMWXKXWMNkdk0NMWK0kdkx:.. .. ...     ....'......   .;l    //
//    MMMMMMMMMMMMMMWXNMMMMWWWMWWMMW0xONWXkod0XNKxool,..........  .....','........ .'c    //
//    MMMMMMMMMMMMMMMNNWMMMWNWMWXXXNXxlxXWXkodd00occ,...........  ..'.'''''....'.   .d    //
//    MMMMMMMMMMMMMMWNXXNWWWXNMMWNKOkOxldXWXxccodc;;,...........  ..',,,,,,...'.    :K    //
//    XNMMMMWWWWWWMMWXK00KXXKNWWWWWNOdkd:oXWOc;::;,;,..........    .,,,,,.......   :KM    //
//    NKKXWMWNNXKXNWWNK0Okkk0KXNNNWMNOdoc:xN0c,,,,,,'..........   .;,'.........   :KMM    //
//    MWX0OKWWWWNXKKXNXKOxddxKNNNNWMMXkoc;cK0c''.''','......... ..''..........  .lXMMM    //
//    MWWWXOk0NWMNK0KKXX0dlcldkO0NWWWWKo:;;kO:'..'',,'..........'''''........  ,kNMMMM    //
//    MNNWWNKkddk0000000Okdolc:lOKKKNWWOc,,od,...'.''........',''''......... .cKWMMMMM    //
//    MWWWNXXXKxccoxO00OOxxxxo:;:lxKWMMXl''cc...','''......,,,...........  .;kNMMMMMMM    //
//    MMMMNK00KKKxolldxkkkkxxdc:::cokKNNd'.,,...'.......',;,,''..... ..  .;kNMMMMMMMMM    //
//    MMMMWXK00KXK0kdollloddoolldoclllk0x;'...........',,,,;,,'...   .';,:OWMMMMMMMMMM    //
//    MMWMMNKKKK000OOOkxdolcccccllccccclc,''.......',,,,,,,,,''....'':oloKWMMMMMMMMMMM    //
//    MMWNWWNNXXK0O00OOkxxxdolc:;;;;;;,,'''..........''',,'......';,,:cdKWMMMMMMMMMMMM    //
//    MMWXXNNNXXKOO000OxdxxxdoddxdxOOkxdol:,',;;;''.....',..',,;:loodOXWMMMMMMMMMMMMMM    //
//    MMWNXXXK000000OOOkxxxddodOKK00XWWWWNX0d:,;clccc:;:oxxoxKNWWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWWWWWNNNXK00OOOOOOkOKKKKXNNNWWWMMMWKko;:clodoclkOOKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWWWWNWNWWWNNXKKXNWWNNXXWMMWNNOllolldddOXWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0kKXXXXWMMWWWWMW0kOOkdoldOxodxx0NMMMMMMMMMWKkONMNOONMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXo:dKNWWMMMMMMMMMMWKOkxxkO000XNNWMMMMMMMMMMXdcd0N0cckKNNNNWWMMMM    //
//    MMMMMMMMMMMMMMMXc'dXNMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMWO:;xKKk,,xKXNNWNNWMMMM    //
//    MMMMMMMMMMMMMMNl.lKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,l0XXO,'xXWMMMMMMMMMMM    //
//    MMMMMWOdOKNMMNo.;0WMMXxx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl'lKWMX:.lXWMMMMMMMMMMMM    //
//    MMMMKc,dKXNMWx.;0WMNx,:OXXWMWWWMWWWMMMMMMMWWWMWWWMMMMMXl'dNMMNl.lXMMMMMMMMMMMMMM    //
//    MMMK;.dKXWMWO''0MMNo.;OXNWMNd;xXXklOWMMWWO:lKN0ooNMMMXc'xWMMNd.:XMMNNMMMMMMMMMMM    //
//    MMNl.lKNWMWK:.xWMNx.'kNWMWNx..xNNo.dWMWKk;.cKW0,;KMMK:.dWWWNO,,0MWNXWMMMMMMMMMMM    //
//    MMX:;KMMWXXO;:XWXXx'oWMMNXKc.cXM0,,KMNXx:.'kWWo.dWWKc.lKXNNWk'oWNXNWMMMMMMMMMMMM    //
//    MMWko0XXXNWNxdKNNMXoxXXXXNXolKMMk'lXXXNkcckWMN:,0NXd.:XNXNMMKokXNWMMMMMMMMMMMMMM    //
//    MMMWNXNWMMMMMWWMMMMWXXNWMMMWMMMMNkOXNMMWWWMMMW0k0N0;'OMMWXNMMWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.oWMMMXNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNNWWWWWNWWWWWMWWMWWWWWWWWWK;'0MMMMNNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNKOO0K0000KK00XN00K0K00K000X0';XMMMWXNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNXXXK0KNNXXXXWWXXNNWNNNXXXWXllXMMMWNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ElenNFT is ERC721Creator {
    constructor() ERC721Creator("ElenNFT", "ElenNFT") {}
}
