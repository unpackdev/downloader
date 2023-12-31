// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Caches Crows
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXKKKKKKKKKKKK0KXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okxxdoollllllllllllc;;::clodxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxdollllllllllllllccclllc:,,,,,,,,,,;:codk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxollclllllllllllllllllllllllc:;;;;,,,,,,,,,,,,;cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxolllcccccllllllllllllllllllllllcccccc:::;,,,,,,,,,,,,;:okKNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxolcllllcllllccllllllllllllllllllllcllcclllc:,,,,,,,,,,,,,,,,:lxKNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWX0xolllcllclllllllllllllccllllllllllllllllllllll:;,,,,,,,,,,,,,,,,,,,:okXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKkollccccllcclllllllllllloolllllllllllllllllllllllc;;;,,,,,,,,,,,,,,,,,,,;cdKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKkolclcllllllcclllllllooddxxxolllllllllllllllllllllllllcc::;,,,,,,,,,,,,,,,,,,:o0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKkolllcclllllllllllloddxxxxxxxxdolllllllllllllllllllllllllllllc::;,,,,,,,,,,,,,,,,:o0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXOdllllllllllllllllodxxxxxxxxxxxddolllllllllllllllllllllllllllllllllc:;,,,,,,,,,,,,,,,:dKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0dlllllllllllllllodxxxxxxxxxxddooollllllllllllllllllllllllllloolllllloddl:;,,,,,,,,,,,,,;ckNMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXkollllllllllllloodxxxxxxxxxxxxdollllllllllooooooooollllllllllodxddolodxxxxdoc;,,,,,,,,,,,,,;dKWMMMMMMMMM    //
//    MMMMMMMMMMMMMWKxllllllllllllloodxxxxxxxxxxxxxxxdolodxkOO0KKKXXXXXXKK0OOkxdolodxxxxxxdxxxxxxxxoc;,,,,,,,,,,,,,c0WMMMMMMMM    //
//    MMMMMMMMMMMMN0dlllllllllllllodxxxxxxxxxxxxxxxxkOO0KXWWMMMMMMMMMMMMMMMMMWWXK0OOkxxxxxxxxxxxxxxxxoc;,,,,,,,,,,,,:kNMMMMMMM    //
//    MMMMMMMMMMMNOollllllllllllodxxxxxxxxxxxxxxxkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOkxxxxxxxxxxxxxxdl;,,,,,,,,,,,,:xNMMMMMM    //
//    MMMMMMMMMMNOollllllllllllc:loxxxxxxxxxxxxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxxxxxxxxxxxxxxo:;,,,,,,,,,,;c0WMMMMM    //
//    MMMMMMMMMW0ollllllllllll:;,,;:ldxxxxxxkOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxdc;,,,,,;coxOKWMMMMMM    //
//    MMMMMMMMW0dlllllllllllc:,,,,,;cdxxxxxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxxxdl;;cok0XWMMMMMMMMMM    //
//    MMMMMMMWXxllllllllllll:,,,,,;ldxxxxk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxxxxkO0OKNWMMMMMMMMMMMMMM    //
//    MMMMMMMNkolllllllllll:,,,,,,:oxxxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxkkOKXNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWKdlllllllllll:;,,,,,,;;:loxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kxxxxxxxxxxxkO0KXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNklllllllllllc;,,,,,,,,,,,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kxxxxxxxkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMWKdlllllllcllc:,,,,,,,,,,,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkxxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWWOollllllccllc;,,,,,,,,,,,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNklllllllccll:;,,,,,,,,,,;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXxllllllllllc:,,,,,,,,,,,c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdllllllllllc;,,,,,,,,,,,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdllllllllllc;,,,,,,,,,,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdllllllllllc;,,,,,,,,,,,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXdllllllllllc:,,,,,,,,,,,cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNxllllllllllc:,,,,,,,,,,,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMWkllllllllcllc;,,,,,,,,,,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMW0olllllllcllc:,,,,,,,,,,,:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMXxllllllllllc:;,,,,,,,,,,,c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMWOlllllcclcclc:,,,,,,,,,;;cxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXxlcllcllccllc;,,,;;::cllloxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMW0ollcllllllllc::cclllllllllxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNklllllllloodddolllllllllllloOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMXxllloodxxxxxxdollllllllllllld0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxxxxxk0XNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMXkdxxxxxxxxxxxdolllllllllllllodOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxxxxxxxxxkk0XNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNOxxxxxxxxxxxxxdolllllllllllllldk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0OkxxxxxxxxxxxxxxxxOKNWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWN0xxxxxxxxxxxxxdolllllllllllllllodk0KNWMMMMMMMMMMMMMMMMMMMMMMMWNKOxolloxxxxxxxxxxxxxdolloxOKNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0kxxxxxxxxxxxxxdolllllllllllllllllodkO0KXNNWWWMMMMMWWWNNXK0OxdlllllclodxxxxxxxxxdollllllloxOXWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkxxxxxxxxxxxxxxdollllllllllllllllllllloodxxxkkkkkkxxdoolllccllclllodxxxxxxxxdoollllllllllloxKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXOxxxxxxxxxxxxxxxdoollllllllllllllllllllllccclllccllllllcllcclloddxxxxxxxxdoollllllllllllloxKWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKkxxxxxxxxxxxxxxxddollllllllllllllllllcllllllllllllllllllclllodxxxxxxddollllllllllllllldONMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxxxxdoollcllcccllllclccclllllllllllllllcllclcloxxxddolllllllllllllllldkXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWX0kxxxxxxxxxxxxxxxxxddoolllccllcllllcccclllllllcccllllllllllooolllllllllllllllllokKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWN0kxxxxxxxxxxxxxxxxxxxxddoolcccccllllllllllllcccccccllllllllllllllc::clllllldkKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNKOkxxxxxxxxxxxxxxxxxxxxdc;;;;;:::::::::::::;;;;;:lllllllllllc:;;,,;:lloxOXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Okxxxxxxxxoloddxxxxl;,,,,,,,,,,,,,,,,,,,,,,,;clllllcc::;,,,,,,,;lkKNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Okxxxxl;,,;:ccll:,,,,,,,,,,,,,,,,,,,,,,,,,;cc:;;;,,,,,,,,;cdOXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0ko:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;cox0NWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdl:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;:ldk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxolc:;,,,,,,,,,,,,,,,,,,,,,,,;:cloxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkkxddoooolllloooddxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CROWS is ERC721Creator {
    constructor() ERC721Creator("Caches Crows", "CROWS") {}
}
