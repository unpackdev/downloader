
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prof. NOTA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    ██████╗ ██████╗  ██████╗ ███████╗    ███╗   ██╗ ██████╗ ████████╗ █████╗     //
//    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝    ████╗  ██║██╔═══██╗╚══██╔══╝██╔══██╗    //
//    ██████╔╝██████╔╝██║   ██║█████╗      ██╔██╗ ██║██║   ██║   ██║   ███████║    //
//    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝      ██║╚██╗██║██║   ██║   ██║   ██╔══██║    //
//    ██║     ██║  ██║╚██████╔╝██║██╗      ██║ ╚████║╚██████╔╝   ██║   ██║  ██║    //
//    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝      ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝    //
//                                                                                 //
//    !Disclaimer!                                                                 //
//    This smart contract was created                                              //
//    for the purpose to deploy                                                    //
//    a collection of the genesis work                                             //
//    that marks the occurrence of Prof. NOTA                                      //
//    on the blockchain.                                                           //
//                                                                                 //
//    This happened simultaneously                                                 //
//    with the emergence of Prof. NOTA                                             //
//    in the IDNFT Academy.                                                        //
//                                                                                 //
//    This genesis of Prof. NOTA's collection                                      //
//    is part of The King's NFT,                                                   //
//    an NFT project by @MyMyReceipt.                                              //
//                                                                                 //
//    The complete story                                                           //
//    can be read here:                                                            //
//    https://github.com/the-aha-llf/the-kings-nft/wiki/The-Project                //
//                                                                                 //
//    Prof. NOTA - @MyReceiptt - @MyReceipt                                        //
//                                                                                 //
//    ██████╗ ██████╗  ██████╗ ███████╗    ███╗   ██╗ ██████╗ ████████╗ █████╗     //
//    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝    ████╗  ██║██╔═══██╗╚══██╔══╝██╔══██╗    //
//    ██████╔╝██████╔╝██║   ██║█████╗      ██╔██╗ ██║██║   ██║   ██║   ███████║    //
//    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝      ██║╚██╗██║██║   ██║   ██║   ██╔══██║    //
//    ██║     ██║  ██║╚██████╔╝██║██╗      ██║ ╚████║╚██████╔╝   ██║   ██║  ██║    //
//    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝      ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝    //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract NOTA is ERC721Creator {
    constructor() ERC721Creator("Prof. NOTA", "NOTA") {}
}
