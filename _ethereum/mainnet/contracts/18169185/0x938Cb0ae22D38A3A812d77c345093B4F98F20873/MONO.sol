// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VERDANDI MONOLITHS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//               ===========                                                                                                                                       //
//              .@@@@@@@@@@%                                                                                                                                       //
//              .@@@@@@@@@@%                                                                                                                                       //
//    	         ===========                                                                                                                                        //
//              .XXXXXXXXXX%                                                                                                                                       //
//              .XXXXXXXXXX%                                                                                                                                       //
//              .XXXXXXXXXX%                                                                                                                                       //
//              .XXXXXXXXXX%                                                                                                                                       //
//              .XXXXXXXXXX%                                                                                                                                       //
//              .XXXXXXXXXX%  _  _ ____ ____ ___  ____ _  _ ___  _                                                                                                 //
//              .XXXXXXXXXX%  |  | |___ |__/ |  \ |__| |\ | |  \ |                                                                                                 //
//              .XXXXXXXXXX%   \/  |___ |  \ |__/ |  | | \| |__/ |                                                                                                 //
//              .XXXXXXXXXX%  __  __  ___  _   _  ___  _     ___ _____ _   _ ____                                                                                  //
//               =========== |  \/  |/ _ \| \ | |/ _ \| |   |_ _|_   _| | | / ___|                                                                                 //
//              .@@@@@@@@@@% | |\/| | | | |  \| | | | | |    | |  | | | |_| \___ \                                                                                 //
//              .@@@@@@@@@@% | |  | | |_| | |\  | |_| | |___ | |  | | |  _  |___) |                                                                                //
//              .@@@@@@@@@@% |_|  |_|\___/|_| \_|\___/|_____|___| |_| |_| |_|____/                                                                                 //
//               ===========                                                                                                                                       //
//    	        	         "Arte ad astra tendens"       			©2023                                                                                                    //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//      "In the vast tapestry of the world, the MONOLITHS stand as timeless sentinels,                                                                             //
//      marrying the ethereal realm of digital art with the grounding anchor of our                                                                                //
//      Earth's geography. Every location is a canvas, every viewer a witness to                                                                                   //
//      art's evolution." — Verdandi                                                                                                                               //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MONO is ERC721Creator {
    constructor() ERC721Creator("VERDANDI MONOLITHS", "MONO") {}
}
