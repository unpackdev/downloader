
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ParadigmStories
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dl:,''''''';:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:'.''''''''''''..':xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;''''''''''''''''''''';xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMKl'''''''''''''''''''''''''lXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXl'''''''''''''''''''''''''''oNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMk,.'''''''''''''''''''''''''.,kMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNo.''''''''''''''''''''''''''''dWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNo.''''''''''.,oko,.'''''''''''oWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx''''''''''':OWMWk;'''''''''.,kMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMK:.''''''''lKMMMMW0c''''''''.cXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMW0:'''''.,dNMMMMMMMXo'.''''':0MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl'''';kWMMMMMMMMMNx;.'.'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc,cKWMMMMMMMMMMMW0:,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKNMMMMMMMMMMMMMMMXKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWNXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMN0xol:;;;;;:ldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xoc:;;;;;cldkKWMMMMMMMMMMM    //
//    MMMMMMMMWKd:,..'''''''''.'cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:..'''''''''.',cxXMMMMMMMMM    //
//    MMMMMMMXd;'''''''''''''''lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c''''''''''''''';xNMMMMMMM    //
//    MMMMMW0:''''''''''''''.,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo''''''''''''''''lKMMMMMM    //
//    MMMMM0:.'''''''''''''':OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.''''''''''''''cXMMMMM    //
//    MMMMXl.''''''''''''''lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:'''''''''''''''dWMMMM    //
//    MMMM0;.'''''''''''',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl'''''''''''''.cKMMMM    //
//    MMMMO,.'''''''''''';loooooooooooodXMMMMMMMMMMMMMMMKoooooooooooooc,''''''''''''.:KMMMM    //
//    MMMM0:.''''''''''''............'.:KMMMMMMMMMMMMMMMO,.''..........'''''''''''''.lXMMMM    //
//    MMMMNd'''''''''''''''''''''''''.'dWMMMMMMMMMMMMMMMXl'''''''''''''''''''''''''.,kWMMMM    //
//    MMMMMXl'''''''''''''''''''''''''lXMMMMMMMMMMMMMMMMMKc'''''''''''''''''''''''''dNMMMMM    //
//    MMMMMMXo,''''''''''''''''''''.,dXMMMMMMMMMMMMMMMMMMMKl'.'''''''''''''''''''.;xNMMMMMM    //
//    MMMMMMMWOl,.'''''''''''''''.,l0WMMMMMMMMMMMMMMMMMMMMMNkc'.'''''''''''''''',o0WMMMMMMM    //
//    MMMMMMMMMW0dc,'....'....',cd0WMMMMMMMMMMMMMMMMMMMMMMMMMNOo:,'.........';lxKWMMMMMMMMM    //
//    MMMMMMMMMMMMWKOxdooloodxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxdooloodk0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract PDS is ERC721Creator {
    constructor() ERC721Creator("ParadigmStories", "PDS") {}
}
