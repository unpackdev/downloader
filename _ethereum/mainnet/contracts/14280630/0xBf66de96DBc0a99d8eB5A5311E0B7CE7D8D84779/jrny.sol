
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: journey
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWOlldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMWk;''',;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MM0:''''''',;lxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWx,''''''''''',:ox0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MNo,''''''''''''''',;:ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MXl''''''''''''''''''''',:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MXl'''''''''''''''''''''''':kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MXo''''''''''''''''''''''''',dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWx,''''''''''''''''''''''''',lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMKl'''''''''''''''''''''''''',lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNWWWWWWNNXK0OkkkOKWM    //
//    MMW0c'''''''''''''''''''''''''',oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdoc::cclllllcc:;;,,''',;dN    //
//    MMMWKl,''''''''''''''''''''''''';kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKko:,''''''''''''''''''''''''cK    //
//    MMMMMXx:,''''''''''''''''''''''''c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;,'''''''''''''''''''''''''''lX    //
//    MMMMMMWKd:,'''''''''''''''''''''',c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,''''''''''''''''''''''''''''';kW    //
//    MMMMMMMMWXOxoc;,''''''''''''''''''';oO0000KXXNNWMMMMMMMMMMMMMMNkc,'''''''''''''''''''''''''''''',oXM    //
//    MMMMMMMMMMMMWNK0kxdollcc:,''''''''''',,,,,;;::cldxkOKXWMMMMMW0l,''''''''''''''''''''''''''''''''c0MM    //
//    MMMMMMMMMMMMMMMMMMMWWWWNXOo;''''''''''''''''''''''',,:ldkkkxo;''''''''''''''''''''''''''''''''':OWMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0l,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',l0WMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXo,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',:xXMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0c,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',cxKWMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0:'''''''''''''''''''''''''''''''''''',:oxkxdl:;,''''''''''',;coONWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMKc',:oo:,''''''''''''''''''''''''''''',lKWMMMMWNK0kxddddddddxOKNWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNd;lONWWKl,'''''''''''''''''''''''''''';kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKlxNMMMMWx,'''''''''''''''''''''''''''';kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0xXMMMMMNd,'''''''''''''''''''';okko;'';kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0xXMMMMM0c'''''''''''''''''''':OWMMWO:';OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0oOWMMW0c,''''''''''''''''''';kWMMMMWx,cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXo:xOxl;'''''''''''''''''''''lKMMMMMWk:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWO;',''''''''''''''''''''''''lXMMMMMXddNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNo,''''''''''''''''''''''''';xNMMWKddXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWk;'''''''''''''''''''''''''',lkkocdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc''''''''''''''''''''''''''''',cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNo,''''''''''''''''''''''''''';l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk;''''''''''''''''''''''''',:dkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKc'''''''''''''''''''''''',lxxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXo''''''''''''''''''''',,:oxkxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx,''''''''''''''''''',codxxxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx,'''''''''''''''''';lxxxkkxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNd,'''''''''''''''',:oxkxxkxxkx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNd,''''''''''''''',:dxkkxxxkxxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNx;''''''''''''''':dxxxxxxxxxxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNOl;'''''''''''',cdxxxxxxxxxxxxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXkxdc;,'''''',,:oxxxxxxxxxxxxxxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWKkxxxdolcccclodxxxxxxxxxxxxxxxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN0kkxxxkkxxxxkxxxxxxxxxxxxxxxxxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNOxxxxkkxxxxxxxxxxxxxxxxxxxxxxxxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKkxxxxkkxxxxxxkxxxxxxkkxxxxxxxxkxOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0kxxkkxxkkxxxxxxxxxxxkkxxxxxxxxxxkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXOxkxxkkxxxxxxxxxxxxxxxxxxxxxxxxkxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN0kxxxxkkxxxxxxxxxxxxxxxxxxxxxxxxkkxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMN0kxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxkxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNOkxkxxkxkkxxxxxxxxxxxxxxxxxxxxxxxxkxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkxxkONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXOxxxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkxxkxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkxxkxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNOxkxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkxkxkkkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXkxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkxxkONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkxxkkxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNKOkxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0kxxkkxxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract jrny is ERC721Creator {
    constructor() ERC721Creator("journey", "jrny") {}
}
