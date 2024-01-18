
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oficinas TK Mint, MKIII
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    OFICINAS TK - Porto, Portugal                                                        //
//    mint facilities #3 - ERC721                                                          //
//                                                                                         //
//                                                                                         //
//                                       .@@#( (,%@                                        //
//                                   @@@@@@@@@@@@@@@@@@@&                                  //
//                                %@@@@@@@@@@@@@@@@@@@@@@@                                 //
//                              @@@@@@    /@/     @@@@@@@@@                                //
//                              @@@@/ (              @@@@@@@,                              //
//                             &@@@@       &#@@@.     @@@@@@@@                             //
//                            % @@@@.     &@@@@@@@     @@@@@@@,                            //
//                             @,@@@@     #@@@@@&@     @@@@@@                              //
//                             *&@@@@@,               &@@@@@@                              //
//                              (@@@@&@@@,         @@@@@@@@@                               //
//                                  @@@@@@@@@@@@@@/@@@@@@*                                 //
//                                    (@@@%@@@&@@@@@@@@&                                   //
//                                                                                         //
//                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                            //
//                               @ &@@@@   @%@@@@@@@@@@@@@@@@@@(                           //
//                                          .@@@@          (@@                             //
//                                     @    .@@@    @@@@.                                  //
//                                  *@@@@@. .@@@    @@@@@@                                 //
//                                @@@@@@@   @@@@@  @@@@@@@@@@                              //
//                              *@@@@@@     .@@@@,   @@@@@@@                               //
//                                @@@@      .@@@(%    @@@@@@@.                             //
//                                @&          @@/@&      @@@@@@                            //
//                                                @        @@@                             //
//                                                                                         //
//    @oficinastk                                                                          //
//    https://oficinastk.github.io                                                         //
//                                                                                         //
//    [There is a ten percent (10%) resale royalty embedded in the smart contract, and-    //
//    that Resale Royalty will be paid out of any gross amount you receive when you----    //
//    sell any NFT originating from this contract. If you sell any NFT originating-----    //
//    from this contract on a marketplace or in a manner that does not automatically---    //
//    recognize and send the Resale Royalty to oficinastk.eth for the Artist’s benefit-    //
//    you may be held personally responsible for the amount that should have been paid-    //
//    to oficinastk.eth for the Artist’s benefit upon resale.]-------------------------    //
//    ----------oficinastk.eth - 0xa4aD045d62a493f0ED883b413866448AfB13087C------------    //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract OTKMKIII is ERC721Creator {
    constructor() ERC721Creator("Oficinas TK Mint, MKIII", "OTKMKIII") {}
}
