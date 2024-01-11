
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stay NFTy landscape art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//      ██████ ▄▄▄█████▓ ▄▄▄     ▓██   ██▓    ███▄    █   █████▒▄▄▄█████▓▓██   ██▓                         //
//    ▒██    ▒ ▓  ██▒ ▓▒▒████▄    ▒██  ██▒    ██ ▀█   █ ▓██   ▒ ▓  ██▒ ▓▒ ▒██  ██▒                         //
//    ░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄   ▒██ ██░   ▓██  ▀█ ██▒▒████ ░ ▒ ▓██░ ▒░  ▒██ ██░                         //
//      ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██  ░ ▐██▓░   ▓██▒  ▐▌██▒░▓█▒  ░ ░ ▓██▓ ░   ░ ▐██▓░                         //
//    ▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ░ ██▒▓░   ▒██░   ▓██░░▒█░      ▒██▒ ░   ░ ██▒▓░                         //
//    ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░  ██▒▒▒    ░ ▒░   ▒ ▒  ▒ ░      ▒ ░░      ██▒▒▒                          //
//    ░ ░▒  ░ ░    ░      ▒   ▒▒ ░▓██ ░▒░    ░ ░░   ░ ▒░ ░          ░     ▓██ ░▒░                          //
//    ░  ░  ░    ░        ░   ▒   ▒ ▒ ░░        ░   ░ ░  ░ ░      ░       ▒ ▒ ░░                           //
//          ░                 ░  ░░ ░                 ░                   ░ ░                              //
//                                ░ ░                                     ░ ░                              //
//                                                                                                         //
//                   __    ___.               ___________ ____. _________   _____ _____________________    //
//    _____ ________/  |_  \_ |__ ___.__. /\  \__    ___/|    |/   _____/  /  _  \\______   \__    ___/    //
//    \__  \\_  __ \   __\  | __ <   |  | \/    |    |   |    |\_____  \  /  /_\  \|       _/ |    |       //
//     / __ \|  | \/|  |    | \_\ \___  | /\    |    /\__|    |/        \/    |    \    |   \ |    |       //
//    (____  /__|   |__|    |___  / ____| \/    |____\________/_______  /\____|__  /____|_  / |____|       //
//         \/                   \/\/                                  \/         \/       \/               //
//                                                                                                         //
//    This is an exclusive landscape art project created by TJSART and presented by Dig-A Hash             //
//    Holdings. This series of 14 original but derived pieces + 1 "OG" edition of "Stay NFTy"              //
//    was created for NFTy Stays, a branded line of Web3, NFT, Augmented Reality,                          //
//    Virtual Reality, and Metaverse immersive short-term rentals. Dig-A Hash minted                       //
//    these art pieces on the block chain as a innovative way to provide another avenue for                //
//    NFT Artist and Projects to expose and sell their work.                                               //
//                                                                                                         //
//    A physical print of the “OG” edition will be featured in a DEGENDISPLAY at one of the                //
//    1st proof of concept NFTy Stays.                                                                     //
//                                                                                                         //
//    All 15 pieces of art NFTs give their holders unique pieces of landscape                              //
//    art, exclusive rights to the IP of the art of their owned NFT and 1/15                               //
//    ownership of the physical DEGENDISPLAY print of the “OG” edition inside a NFTy Stay.                 //
//                                                                                                         //
//    The small owner group of this series will also have a 1 year lease on dedicated wall                 //
//    space inside a NFTy Stay for the "OG" edition display. With this 1 year lease comes the              //
//    ability to license the IP of the “OG” edition held by NFTy Stays Treasury. Each of the 15            //
//    NFTs will represent 6% of any earned revenue from this IP lease with the remaining 10%               //
//    going to the NFTy Stay Treasury                                                                      //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SNART is ERC721Creator {
    constructor() ERC721Creator("Stay NFTy landscape art", "SNART") {}
}
