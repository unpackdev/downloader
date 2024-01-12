
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Geodetica
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//            ██████╗ ███████╗ ██████╗ ██████╗ ███████╗████████╗██╗ ██████╗ █████╗             //
//            ██╔════╝ ██╔════╝██╔═══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝██╔══██╗           //
//            ██║  ███╗█████╗  ██║   ██║██║  ██║█████╗     ██║   ██║██║     ███████║           //
//            ██║   ██║██╔══╝  ██║   ██║██║  ██║██╔══╝     ██║   ██║██║     ██╔══██║           //
//            ╚██████╔╝███████╗╚██████╔╝██████╔╝███████╗   ██║   ██║╚██████╗██║  ██║           //
//             ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝           //
//                                                                                             //
//    MMMMMMMMMMMMMMW0xdxKWMMWWNXKK0KKXXNWWMMMMMMMMMMMMMM by MintFace MMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMWOdddx0XKkdolllcllloodxk0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMKxdddddlcccccccccccccccclloxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMNOdddlcccccccccccccccccccccccldkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMW0xddlccccccccccccccccccccccccccokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMXkddolcccccccccccccccccccccccccccokXWMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMNOddddolccccccccccccccccccccccccccloOXWMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMW0xddxOxllccccccccccccccccccccccccccldOXWMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMXxddxKXkdollccccccccccccccccccccccccclokKWMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMNkddd0WN0xdoooddolccccccccccccccccccclloxKWMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMW0dddONMWKkdddk0KK0kxdooollllllloodkO0KNWWMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMKxddkXMMWXOxddx0NMMMWNNNXXKKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMXxddxKMMMMW0xdddkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMNkddx0WMMMMWXOxddx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMNOdddOWMMMMMMWKkdddkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMW0dddONMMMMMMMWXOxddxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMWKxddkNMMMMMMMMMWKkddddx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMMKxddkXMMMMMMMMMMMN0xddddkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMMKxddxXMMMMMMMMMMMMWXOkxdddkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMMXxddxKMMMMMMMMMMMMMMWNXOxddxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMMXkddxKMMMMMMMMMMMMMMMMMWXOxddxkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMMMMWKxoodOXNNWMMMMMMMMMMMMMMMWKOxdddkKNWNXXXXNNWWMMMMMMMMMMMMMMMM         //
//    MMMMMMMMMMMMMWWX0kdl:;;;::clodk0NWMMMMMMMMMMMMWXOdlccllc::::ccldx0XWMMMMMMMMMMMM         //
//    MMMMMMMMMMMWXOdc;,,,,,,,,,,,,,,;cdONWMMMMMMMMMN0d:,,,,,,,,,,,,,,,,:okXWMMMMMMMMM         //
//    MMMMMMMMMWXxc,,,,,,,,,,,,,,,,,,,,,;ckXWMMMMMNOl;,,,,,,,,,,,,,,,,,,,,,:xKWMMMMMMM         //
//    MMMMMMMMNOc,',,,,,,,,,,,,,,,,,,,,,,,,lOWMMWKo;,,,,,,,,,,,,,,,,,,,,,,',,:kNMMMMMM         //
//    MMMMMMMNx;,,,,,,,,,,,,,,,,,,,,,,,,,,,,:kXXOc,,,,,,,,,,,,,,,,,,,,,,,,',,,;dXMMMMM         //
//    MMMMMMNx;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;cl:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,dXMMMM         //
//    MMMMMW0c,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;kWMMM         //
//    MMMMMNd,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,oXMMM         //
//    MMMMMXo,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,cKMMM         //
//    MMMMMXo,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,lKMMM         //
//    MMMMMNx;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,oXMMM         //
//    MMMMMWKl,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:OWMMM         //
//    MMMMMMWO:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,cddl,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;kNMMMM         //
//    MMMMMMMWOc,,,,,,,,,,,,,,,,,,,,,,,,,,,,l0NWKo;,,,,,,,,,,,,,,,,,,,,,,,,,,,:kNMMMMM         //
//    MMMMMMMMWKd;,,,,,,,,,,,,,,,,,,,,,,,,:dXWMMMXkc,,,,,,,,,,,,,,,,,,,,,,,,;o0WMMMMMM         //
//    MMMMMMMMMMN0d:,,,,,,,,,,,,',,,,,,,:dKWMMMMMMWXxc;,,,,,,,,,,,,,,,,,,,:oONMMMMMMMM         //
//    MMMMMMMMMMMMWXkoc;,,,,,,,,,,,,;cdOXWMMMMMMMMMMWXOdl:,,,,,,,,,,,,;cokKNMMMMMMMMMM         //
//    MMMMMMMMMMMMMMMWXOdl:;,,,,;:ldOXWMMMMMMMMMMMMMMMMWN0xl:;,,,,;;cokKNMMMMMMMMMMMMM         //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract GEO is ERC721Creator {
    constructor() ERC721Creator("Geodetica", "GEO") {}
}
