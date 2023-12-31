// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Broken geometry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▄▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Q▄▄█▒░░█████φφφ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░│▄▄▓███████▒░░█████╠╠╠╠╠╠╠φφ▒░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░▄▄▓██████████████▒░░█████╠╠╠╠╠╠╠╠╠╠╠╠╠╠φφ░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░▄▄▓████████████████████▒░░█████╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠φφ░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫██████████████████████▒░░█████╠╠▄▒▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫████████████╩║████▒╓║█▒░░█████╠╣▄▄╬╠▀▀▓▓▓▒╠╠▒╠╠╠╠╠╠╠╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▓╩└└└░,███▒φ▐████▒╠╟█▒░░█████╠╫██▀▀█████▒╠╠╬╬▓▓▓▓▓▒╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒░  ░░▒███▒▒▐████▒╬╣█▒░░█████╠╫██░╠╠╠╠██╬╠╠▓█▀▀▀▓█▒╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒▓████████▒▒ ║███▒╠╟█▒░░█████╠╫██░╠╠╠╠██╣╠╠█▌]╠╠╟█╬╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒▓████████▒╠ ╙███▒╠╟█▒░░█████╠╫██░╬╠╠╠██╬╠╠█▌▐╠╠╣█╬╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒▓████████▒▒▄µ███▒╠╟█▒░░█████╬╫██░╬╬╬╬██╣╬╬█▌▐╠╠╠╬╬╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒╫▀▀██████▒╠█▌░██▒╬╣█▒▒▒█████╬╫██░╬╬╬╬██╣╬╬█▌▐╬╬╬╬╬╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒╠  ░╠████▒╠██▒██▒╬╣█▒▒▒█████╬╫██░╬╬╬╬██╬╬╬█▌▐╬╬╬╬╬╠░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╫█▒▓████████▒╠██▒╟█▒╬╣█▒▒▒█████╬╫██;▒▒▒▒██╬╬╬█▌▐╬▓▓▓╬╠░░░░░░░░░░░░░    //
//        ▒▒▒▒▒▒▒▒▒▒▒▒▒╫█▒▓████████▒╠███╠╬╬╣╣█▒▒▒█████╬╫█████████╬╬╬█▌▐╬███╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//        ▒▒▒▒▒▒▒▒▒▒▒▒▒╫█▒╫████████▒╠███▓╬╬╬╣█▒▒▒█████╠╫█████████╬╠╬█▌▐╠╬╬█╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//        ╠╠╠╠╠╠╠╠╠╠╠╠╠╫█▒╚▀███████▒╠████╬╬╣╣█▒╠╠█████╬╫██│╬╬╬╬██╬╬╬█▌]╬╠╣█╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠    //
//        ╠╠╠╠╠╬╠╠╬╠╠╠╠╫█▒"  ░╚╚███▒╚████▌╬╬╣█▒╠╠█████╬╫██░╬╬╬╬██╬╬╬██▓████╠╬╠╬╠╬╬╠╠╬╠╠╠╠╠    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╫██▓▄▄▄µ╓███▒"████▌╠╬╟█▒╠╠█████╬╫██░╬╬╬╬▓▓╠╬╬╣╫▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬▓████████████▓████▌,,▐█▒╬╬█████╬╬╠╠φ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╫██████████████████████▒╬╬█████╬╬╬╬▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╠╠╬╠╬╠╬╬╠╬╠╣██████████████████████▒╬╬█████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╣▓╣╬╬╬╬╬╬╬╬╠╬╬╬╬╬╬    //
//        ╠╠╠╠╠╠╠╠╠╬╠╬╬╣▓▓▓▓██████████████████▒╬╬█████╬╬╬╬╬╬╬╬╬╬╣╣▓▓▓▓▓▓▓▓▓╬╬╬╬╠╠╬╬╬╬╬╠╠╬╬    //
//        ╠╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓╬╬╣▓▓███████████████▒╬╬█████╬╬╬╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╠╠    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╣╣▓╬╬╬╬╣▓▓▓█████████████╬╣╣█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╣╬╬╬╣▓▓▓▓▓▓▓█████████▓╣╣▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╣╣╬╬╬╬╣╣▓▓▓▓▓▓▓▓████████▓▓▓▓████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╣╣╣╬╣╣╣▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╬╬╬╬╬╬╬╬╬╬╬╬    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract BG is ERC721Creator {
    constructor() ERC721Creator("Broken geometry", "BG") {}
}
