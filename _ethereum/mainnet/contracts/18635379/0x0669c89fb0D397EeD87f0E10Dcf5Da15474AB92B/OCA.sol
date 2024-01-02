// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On-Chain Architecture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//        ███████      █████████    █████████                                      //
//      ███░░░░░███   ███░░░░░███  ███░░░░░███                                     //
//     ███     ░░███ ███     ░░░  ░███    ░███                                     //
//    ░███      ░███░███          ░███████████                                     //
//    ░███      ░███░███          ░███░░░░░███                                     //
//    ░░███     ███ ░░███     ███ ░███    ░███                                     //
//     ░░░███████░   ░░█████████  █████   █████                                    //
//       ░░░░░░░      ░░░░░░░░░  ░░░░░   ░░░░░                                     //
//                                                                                 //
//    On-Chain                                                                     //
//    Architecture                                                                 //
//    by Janne                                                                     //
//                                                                                 //
//    Always there. Totally decentralized. Complex because it's simple.            //
//    Get into the noise of the revolution. Decentralization means compromise.     //
//    Fully on-chain. #OCA                                                         //
//                                                                                 //
//    https://superrare.com/janne                                                  //
//    https://makersplace.com/janne                                                //
//    https://janne.limited                                                        //
//    https://twitter.com/janne_limited                                            //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract OCA is ERC721Creator {
    constructor() ERC721Creator("On-Chain Architecture", "OCA") {}
}
