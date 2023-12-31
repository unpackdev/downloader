
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mente Ambigua
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▌▀▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▒▀▒▀▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▀▌░╓┌▀▌▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▀╒╛╠╦─▀▒▌▌▌╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌░─╘┴╞╚░╒▀▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╙╓╚▀▓▓▓▓▓▓▓▌▌▌▌▌▌▌▌▌▌▀▀▀▒▌▒▌▌╢▓▀▌▒▒▀▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓╫▓▓▓▀╦╢▒╫▌▒╦▀▓▓▓▓▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▀▀▄╗▒▒▒▒▀╫▀╫▀▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓╫▓▀░├╝╝╬▀▀╝╟┘├▀▌▓╫▌▌▌▒▌▌▌▌▌▌▌▀▀▄╪╝╠╠╠╣▒▒▒║▀▓▒▀▄▀▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓▄╘╙▒▀▒═╘╝▀░╓▄▌▌▒▌▓▀▌▒▌▌▌▀▀╪╠╝▄▀▀▒▄╝║▒▒▀▒▒▌▌▀▄▒▒▀╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓▌▒│▀▀═░┌╔▒▓▓▓▒▌▀▓▌▌▌▀▀▄╬▄╨╪╟▀▄▄▄▀╪╪▒▒║▀▀▄▒▒▒▒▒▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌╗╕╖▒▓▓▓▓▓▌▌▌▌▌▀▄╬▌▀▌▒▌╟▄╝╪▀▄╠╠┤▒▒▒▒▒▒▒▒▒▒▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▀▌▌▌▌▀║▀▀░░░░░░┌┌╓┌┌░░░╚▄▄▄╖▀▀▀▀▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▒▒▒▀▌▌▌╣▒▒╫╩░░░░╓▄▒▒▒▒▒▒▒▒▄╓░░╘▀▄╠╝▒▒▒╝╪╟╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▌▌▒▒▒▀▌║▌▒▒▀░░░░╓▒▒▀╚░░░░└╚▀▒▒▒░░░╘╝╗▒▄▓▀╝▄▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▌▌▌▌▌▌▒▒▌▌▌▀▄▓▓▀╟╗╩░░░╡▒▀░░░░░┌┌░░░░▀▒▒░░░▌▄╝╝╠▄▌▌▀▄║▄╬▌▌▓▌▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓╫▌▌▌▌▌╫▌▌╫▌▌▌▒▀╟╩║▌│░░┌▒▒░░░┌▒▀╘╘╚▒▄░░▒▒░░┌╨╡▌▄▒▓▓▌╬║║╙▀╫▌▌▌▓▌▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▌▌▌▌▌▌▌▌▌▌▒▌▌▌▒▄╨╡▌░░░▐▒▒░░░▒▌░▒▌░┌▌░░▒▒░░╒▄▄▌▀▒▌▓▓▌╢▀╖╝▒▀▌▌▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▄╗░░░░▒▒▄░░╙▌▄╥╓▄▒▀░║▒╩░░├▌▀┌╛╥╚▒▌▓▄▒▒▒╣▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▌▌▌▌▓▌▒╗▌▌▓▌░░░░░▀▒▒▄┌░╘╙▀╚╓╗▒▒░░┌▄╫░╘▀░╓▀░╠▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌╟▀▀▒▌▌▌▌▌▓▀╗░░░░╘╝▒▒▒▒▒▒▒▒╝╘░┌╝▓▓╫▌▒░╙▀╔▒▌▌▒▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╝╪╝▄╝╝╡╪╪▀▀┤▄▄▄┌░░░░░░░░░░░░╓▒▓▌▒▌▌▌▌▌▌▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀╪╪╪┤▀╝╝╩╪╪╝╪╦▒▒▒▒▒▄╝▒▄▒║║╝╠▄▌▌▒▀▀▌▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▀╗╩╝▄▌▌╨╗▄╨╝╝╝│▒▀╚║▄┤▒▄▄╠╪▄▒▌▀╬▄▄╟╟▌▌▓▓▓▓▓▌▓▌▀▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▌╝╝╟▒▀▀▌╫▄╬╬╗╩╝╝▒╫▌▀▓╫▒▀▀╪▀▀▌▀╟▌╓▓▀╫▌▓▓▓▓▌▓▌▀╬╬╪▀▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓╩╝╝▀▀╝╝║▓▓▒╝╪╩╪╝║╣▒▒▀▀▄╬╬╬▄╬▄▀▒▒▄╠▌▌╫▓▓▓▓▌▌║▄▄▄▀╬╬▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓╙╝╙╩╪╪╗╟╝▄╩┤╪╝╪╝┤▀▄╟╟╟╬╪▄▄▄▄╟╟╬▄▀▒▒▌▓▓▓▓▓▓▌▌▒▄▄▄▒▓▌▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▄╝╪╝╪╗╨╪╪╝╗▄▄▓▓▓╟╬╬╬╟╝╪▀▀╣▄▄▄╬╬▄╬▄▄▓▓▓▓▓▓▓▌▓▓▓▓▌▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▄▄▄▒▓▓▓▓▓▓▓▓▓▄╬╬║╫▒╪▌▌▀▀▀▄▄╬╬▄╫▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╟╬╟▌▌▌▒▒▒▀▌▀╬╬╬╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌╬▄▒▒▄▌▌▌▌▒▄▄▄╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄║║▄▒▒▀▄▄╪╟╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄╬╬▄▄▄╟╟▄║▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▄╟║╬╬╬▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SIGMA is ERC721Creator {
    constructor() ERC721Creator("Mente Ambigua", "SIGMA") {}
}
