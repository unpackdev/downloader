// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE NINE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░││░░░░░░░░░░░░░░░░░░░░'''''''''''░▒░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░∩░░░░░░░░░░░░░░       ,░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│░░░░░░░░░░░░░░░░░░░░░░░░░;;;;;░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░│░░░░░░▐╬░░░╠╬░░░░░░│░░░░░░░'';░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ;░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒╣╣▒╣╣╣▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╔▓╬╬╬╬╬╬╬╬╬╬╬▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░│░░╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░∩░░░░╟╬╬╬▓╬╬╬╬╬╬╬╬╬▓╬╬▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░]╣███████╬╬╣███████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░╓║╬▓█▀╬╠▀█╬╬╬█▀╬╠▀█▓▌▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░╬╬▄φ≥╬╠╬╬╩╠╬▒╠╬╬╠╬≥▄╣▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░╣╬╬╬▓▒╣╬╣╣╬╬╬▓╬╫▓▓▓╬╬▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░│╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╙░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╟╬╬╬╬╬╬▓▓▓▓▓╬╬╬╬╬╬▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╣╬╬╬╬▓▓╣╬╬▓▓╬╬╬╬╬░░░░░░░░│░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╚╣╬╬╬╬╬╬╬╬╬╣╣╬▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░∩░░░░░░░░╚╣╣╬╣╬╬╬╬╣╬╣╣░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╬╬╣╬╬╬╬╬╬╬╬╬░φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║╬╬╬╬╬╬╬╬╬╬╬╣▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▌╠╬╩╙╙╙╙╚╠╬╠▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▄#╬╠▒▐▒▒░▒╚▒▒▒▌]▒╟▓▄▄░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░░▄▄▓██╬╣╣╬╬╬╬╬╬╬╬║╬╬╬╬╣╟▓φ╣╣╬║╬╬╬╬╬╬╬╬╬╬╬╣╣╣██▓▓▄░░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░░░░@╬██▒▓█╬╬╬╬╣╣╣╣╬╬╠╣▓╬╬╣╣╬╚╬╬╬╬╣▓╬╝╣╣╣╣╣╣╬╬╬██╬██╬▓░░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░░░Γ└╟█▓╬▓█▓╣█╬╬╬╬╬╬╬╩░╠╬╬╬╬╬╣▒]╣╬╬╬╬╬╬░╙╬╬╬╬╬╬╬██▓█▓╬▓█▌░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░░"   ╢╬╬██╬██╬█╬╬╬╬╬╩ ░╣╬╬╬╬╬╣▓▓╬╣╬╬╬╬╣░ ╙╬╬╬╬╬████╬███╬╬░░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░░░░░ ....╬╬╬╣╬██▓█▓█╬╬╬▒  ╬╬╬╬╬╬╬╣▒φ╬╬╬╬╬╬╬╣~ ╙╣╬╬███▓▓█╬╣╬╬╬▒░░░░░░░░░░░░░    //
//                                                                                        //
//    φ░░░░Γ└'''''└░╬╬╬▒╬╬╬█████▓╬░²╣▓▓╬╬╬╬╬╟▒▄╬╠╬╬╬▓▓▓▓Σ░╠▓█████╬╬╬╬╬╬╬▒ΓΓΓΓ░░░░░░░░░    //
//                                                                                        //
//    φ░░Γ         :╬╬╬╣╬╬╣╬╬████╬▒▓████████▓█▀██████████φ╠╬███╬╬╬╬╬▒╟╬╬▒░░░░░░░░░░░░░    //
//                                                                                        //
//    ╙╙            ╬╣▓╬╬╬╬╬╬╣██▓╬▓██████████▒Σ╫██████████╠╬╣██╬╬╬╬╬╬╬╣╬▒░░░░░░░░░░░░░    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MUSE is ERC721Creator {
    constructor() ERC721Creator("THE NINE", "MUSE") {}
}
