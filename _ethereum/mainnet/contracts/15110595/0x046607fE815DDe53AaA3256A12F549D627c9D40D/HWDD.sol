
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HANNESWINDRATH.ETH - DAY DREAMS COLLECTION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    ▓█████▄  ▄▄▄     ▓██   ██▓   ▓█████▄  ██▀███  ▓█████ ▄▄▄       ███▄ ▄███▓  ██████      //
//    ▒██▀ ██▌▒████▄    ▒██  ██▒   ▒██▀ ██▌▓██ ▒ ██▒▓█   ▀▒████▄    ▓██▒▀█▀ ██▒▒██    ▒      //
//    ░██   █▌▒██  ▀█▄   ▒██ ██░   ░██   █▌▓██ ░▄█ ▒▒███  ▒██  ▀█▄  ▓██    ▓██░░ ▓██▄        //
//    ░▓█▄   ▌░██▄▄▄▄██  ░ ▐██▓░   ░▓█▄   ▌▒██▀▀█▄  ▒▓█  ▄░██▄▄▄▄██ ▒██    ▒██   ▒   ██▒     //
//    ░▒████▓  ▓█   ▓██▒ ░ ██▒▓░   ░▒████▓ ░██▓ ▒██▒░▒████▒▓█   ▓██▒▒██▒   ░██▒▒██████▒▒     //
//     ▒▒▓  ▒  ▒▒   ▓▒█░  ██▒▒▒     ▒▒▓  ▒ ░ ▒▓ ░▒▓░░░ ▒░ ░▒▒   ▓▒█░░ ▒░   ░  ░▒ ▒▓▒ ▒ ░     //
//     ░ ▒  ▒   ▒   ▒▒ ░▓██ ░▒░     ░ ▒  ▒   ░▒ ░ ▒░ ░ ░  ░ ▒   ▒▒ ░░  ░      ░░ ░▒  ░ ░     //
//     ░ ░  ░   ░   ▒   ▒ ▒ ░░      ░ ░  ░   ░░   ░    ░    ░   ▒   ░      ░   ░  ░  ░       //
//       ░          ░  ░░ ░           ░       ░        ░  ░     ░  ░       ░         ░       //
//     ░                ░ ░         ░                                                        //
//                                                                                           //
//                                                                                           //
//    HANNESWINDRATH.ETH "DAY DREAMS" COLLECTION                                             //
//                                                                                           //
//    #ALL PIECES SHOT ON FILM                                                               //
//                                                                                           //
//    #THIS COLLECTION SHOWS ALL PIECES OF MY                                                //
//     FIRST BOOK CALLED "DAY DREAMS" THE INCOME                                             //
//     OF SALES GOES INTO THE PRINT COSTS TO                                                 //
//     REALIZE THE PROJECT                                                                   //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract HWDD is ERC721Creator {
    constructor() ERC721Creator("HANNESWINDRATH.ETH - DAY DREAMS COLLECTION", "HWDD") {}
}
