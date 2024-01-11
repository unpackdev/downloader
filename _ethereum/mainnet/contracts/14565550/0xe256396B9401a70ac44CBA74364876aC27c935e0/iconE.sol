
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: (icon) universe - Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloolllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllxK0ollllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllolxNXxloolll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllld0KKXWWXKK0dll    //
//    lllllllllllllllloolllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllodllllllllllloxxxONNOdxdoll    //
//    llllllllllllllokKxlllllllllodollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllld00dllllllllllllldXNxllllll    //
//    llllllllllllld0Nklllllllld0NNN0olllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllldXXklllllllllllldXNxllllll    //
//    llllllllllllxXWOlllllllllxNMMMXxlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllxXNOolllllllllldKNxllllll    //
//    lllllllllllkNMKolllllllllox000xlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllkNWOolllllllllo0Kxllllll    //
//    llllllllllkNMNxlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllo0MWOollllllllloolllllll    //
//    lllllllllkNMM0olllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcllllclllllllllllllllllllllllllllllllllllllllllllllxNMWOllllllllllllllllll    //
//    llllllllxXMMNxllllllllllllllllllllllllllllllllllllllllllllllllllllllcccccccccccccccccclllllllllllllllllllllllllllllllllllllllllo0MMNklllllllllllllllll    //
//    llllllloKMMMKolllllllllllllllodollllllllllllllodxxxxxdolllllllllclccccccc:::::::cccccccclllllllllllodolllodxxxxdolllllllllllllllkWMMXdllllllllllllllll    //
//    lllllllkNMMM0llllllllloxxkkOKXNOllllllllllldk0KOkxxxxkO0Oxlllllccccc::;,,,,,,,,,,;;:ccccccclooddxk0XXxokOO00KNWWX0xllllllllllllldXMMWOllllllllllllllll    //
//    lllllloKMMMWkllllllllloxxkXMMMWOllllllllld0NWKxllllllco0WNKdlccccc:;,,,,,,,,,,,,,,,,,;:ccccldxxONWWMN0kxolllld0WMMWOollllllllllloKMMMXdlllllllllllllll    //
//    llllllxXMMMNxllllllllllllo0MMMWOlllllllokNMMKdlllllllldXWWWKocccc;,,,,,,,,,,,,,,,,,,,,,;cccccccoKWWMWOlllllllloKMMMNxllllllllllloKMMMWOlllllllllllllll    //
//    llllllkWMMMXdllllllllllllo0MMMWOlllllloOWMMNxllllllllldKWNNOocc:;,,,,,,,,,,,,,,,,,,,,,,,;cccclco0WWMNkllllllllo0MMMWOlllllllllllo0MMMM0ollllllllllllll    //
//    llllllOWMMMXdllllllllllllo0MMMWOllllllkNMMMKolllllllllloxxdlccc;,,,,,,,,,,,,,,,,,,,,,,,,,;ccccco0WWWNklllllllll0MMMMOllllllllllll0MMMMKollllllllllllll    //
//    llllllOWMMMXdllllllllllllo0MMMWOlllllo0MMMM0lllllllllllllllccc:,,,,,,,,,,,,,,,,,,,,,,,,,,,:cccco0WWWNklllllllll0MMMM0llllllllllll0MMMMKollllllllllllll    //
//    llllllkWMMMXdllllllllllllo0MMMWOllllldKMMMM0lllllllllllllccccc:,,,,,,,,,,,,,,,,,,,,,,,,,,,:cccco0WWWNklllllllllOMMMM0lllllllllllo0MMMM0ollllllllllllll    //
//    lllllldXMMMNxllllllllllllo0MMMWOllllldKMMMM0olllllllllllllcccc:,,,,,,,,,,,,,,,,,,,,,,,,,,,:cccco0WWWNklllllllllOMMMM0llllllllllloKMMMWOlllllllllllllll    //
//    llllllo0MMMWkllllllllllllo0MMMWOlllllo0MMMMXdllllllllllllllcccc;,,,,,,,,,,,,,,,,,,,,,,,,,;ccccco0WWWNklllllllllOMMMM0llllllllllldXMMMXxlllllllllllllll    //
//    lllllllxNMMWOlllllllllllll0MMMWOllllllxNMMMWklllllllllllllccccc:,,,,,,,,,,,,,,,,,,,,,,,,,:ccclco0WWWNklllllllllOMMMM0lllllllllllxNMMM0olllllllllllllll    //
//    lllllllo0WMMKollllllllllll0MMMWOlllllllkNMMMXxllllllllllloxocccc:,,,,,,,,,,,,,,,,,,,,,,,:cccclco0WWMNklllllllllOMMMMOlllllllllllOWMMXxllllllllllllllll    //
//    lllllllldXMMNxllllllllllll0MMMWOlllllllldKWMMXkolllllllox0Ooccccc:;,,,,,,,,,,,,,,,,,,,;:ccccclco0WWMWklllllllllOMMMMOlllllllllloKMMWOlllllllllllllllll    //
//    lllllllllxNMWOlllllllloxxkXMMMWKkxxolllllox0XWWXOkxxxkOOOdllllccccc:;;,,,,,,,,,,,,,;;:cccccloddkXWWWW0xddlloddxKMMMMKxddollllllkNMW0olllllllllllllllll    //
//    llllllllllkNMXdllllllloxkkkkkkkkkkkdlllllllloxkO0000Okxolllllllcccccccc::;;;;;;;:::ccccccllloxxxkkkkkkxxdlldxxxkkkkkkxxxollllloKMW0ollllllllllllllllll    //
//    lllllllllllkNW0olllllllllllllllllllllllllllllllllllllllllllllllllllcccccccccccccccccccllllllllllllllllllllllllllllllllllllllllOWW0olllllllllllllllllll    //
//    llllllllllllxXNklllllllllllllllllllllllllllllllllllllllllllllllllllllllccccccccccclllllllllllllllllllllllllllllllllllllllllllxNNOollllllllllllllllllll    //
//    llllllllllllldKXkllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllldXXxllllllllllllllllllllll    //
//    lllllllllllllloOKxllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllld00dlllllllllllllllllllllll    //
//    lllllllllllllllloolllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllodlllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract iconE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
