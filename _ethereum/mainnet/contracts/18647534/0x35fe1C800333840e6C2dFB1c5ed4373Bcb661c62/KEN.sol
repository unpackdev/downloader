// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kenny Schachter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╫▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╟▓█╬╬╬██████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬╬▓▓▓▓▓█▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█╬╬╬╬╬╬╬╬╣▓▓▓▓▓█▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█╬╬╬╬╬╬╬╬╬▓▓▓▓▓╣█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╢▓╬▓▓╬▓▓▓╬╣▓▓▓▓█Ñ╬╬╬▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▀▓╬▓╬▓█╬╬█▓▓▓▓█╬╣█▓╬▓▀▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▀▓░╚╬╣╣╬██▓██▓▓▓▓█╬╣╣Ü░╬▓Å▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣Ñ▓╣▓Ü░█╬╣╣╬▓████████▓╬╣▒║▓▓Ñ█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒╙╙░╓▓█╣█████████████▓╬█▒││╟▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██▓▓██▓╣███████████████╬██▓▓██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓██╬╬╬▓╬╬╬▓████████████╬╫╣▓╬╣█▓█▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╢╢╢╢╢╢╬╬╬╬╬╬╬╬╣▓▓██▓╬╬╣╬╣▓╣╣╣╬▓████████▓╬╣╣╣╣╣╬╬╬▓▓▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╠░░░░░░[╬╬╬╬╬╬▓╬▓█╬╬╣╣╬╣╣╬╬╣╣╣╣╬╬▓████▓╬▓╬╣╣╬╬╣╣╬╬╬▓╬▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╠░░░░░░[╬╬╬╬╬╣▓▓╬▓███▓▓▓╙▓▓▓▓▓▓▓▓▓╬╬╬╬╬▓▓█▓█▀▀█▓▓███▓╣▒▒▄▒╬╬╬╬╬╬╬╬╬▒▒▒▒▒╠╬╬╬    //
//        ╬╬╬╬╬░░░░░░[╬╬╬╬╬╢╬╣╬╬╬╬▓▓╬╣█▓▓▓╬╬╣╣╣╣╬╣╬╬╬╣╬╬▓▓▓▓▓▓▓▓▓╬╬╣██╬▒╬╬╬╬╬╬╬╬╬▒▒▒▒▒╠╬╬╬    //
//        ╬╬╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╣╬▓███▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓╬╬╬╬▓████╣▀╙╙█╫╝╣▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╠╬╬╬╬╬╬╬╬╬╬╬█▀▀╙▀╣▓╬╬╬╬╬╬╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╣╣╣╣╣╣╬╬╬╬╬▓Γ        '╠██╬╬╬╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╬╫█▀¬``     `╙▀╫╬╬╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▓╬▓▀              ██▓╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╬╣█▀^             ╙▀▓▓╫╬▓╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▀╙-`              ╓█▓╬╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬╬╬╝"   `             █▒▒╠╠╩╙``¬└└└└▓──       `               ╙▀▒╬╬╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬▓▀`                  ,╬Ñ╙`          ▀╟M                         ╫█▒╬╬╬╬╬    //
//        ╬╬╬╬╬╬╬█▓█"_   `              ▓▌             »φ⌐                         █▒╬╬╬╬╬    //
//        ╬╬╬╬╬╬▓╫█▓█▄∩                 █╬▌             ▌   `                      ▐█▒╬╬╬╬    //
//        ╬╬╬╬╬╬╬╬╬Ñ╙`                  █╠╫_           "█⌐    `                     ╙▀▓▓▓▓    //
//        ╬╬╬╬╬╬╟██    `                ╙▓╠▓_          ▐█_                          ╓▄█▓▓▓    //
//        ╬╬╬╬╬╬╟█⌐                      '▓╠╢▄        ╓▓╬▒                           ▀█╬╬╬    //
//        ╬╬╬╬╬╬▀`   ``  `                ╟▒╠╬▄      ▄╬╠╢Ñ    `                      █╬╬╬╬    //
//        ╬╬╬╬╫Ñ_                          █╠▒Ü╬╗╓;,ÅÑ╠╠╫⌐   ` `                     ╙▓▒╬╬    //
//        ╬╬╬╫Ü     ``                     ╙▒╠╠╠╠╠╠╠╠╠╠╠█                            ,█╬╬╬    //
//        ╬╬╣▌       `                      ╟▒╠╠╠╠╠╠╠╠╠╬▌     `                      ╟╬╬╬╬    //
//        ╬╬╬▌                               ╟▒╩╠╠╠╠╠╠╠▓                             ╘█╬╬╬    //
//        ╬╬╬█       `                        █╠╠╠╬▒╠╠╢Ñ                              ╓╟╬╬    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract KEN is ERC721Creator {
    constructor() ERC721Creator("Kenny Schachter", "KEN") {}
}
