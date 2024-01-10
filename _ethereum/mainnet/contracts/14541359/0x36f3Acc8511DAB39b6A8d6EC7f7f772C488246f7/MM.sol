
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marbelous Minds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//          ___           ___       ___           ___           ___           ___       ___                    //
//         /\  \         /\__\     /\  \         /\__\         /\  \         /\__\     /\  \                   //
//        /::\  \       /:/  /    /::\  \       /::|  |       /::\  \       /:/  /    /::\  \                  //
//       /:/\:\  \     /:/  /    /:/\:\  \     /:|:|  |      /:/\:\  \     /:/  /    /:/\:\  \                 //
//      /::\~\:\  \   /:/  /    /::\~\:\  \   /:/|:|__|__   /::\~\:\  \   /:/  /    /::\~\:\  \                //
//     /:/\:\ \:\__\ /:/__/    /:/\:\ \:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/__/    /:/\:\ \:\__\               //
//     \/__\:\ \/__/ \:\  \    \/__\:\/:/  / \/__/~~/:/  / \:\~\:\ \/__/ \:\  \    \/__\:\/:/  /               //
//          \:\__\    \:\  \        \::/  /        /:/  /   \:\ \:\__\    \:\  \        \::/  /                //
//           \/__/     \:\  \       /:/  /        /:/  /     \:\ \/__/     \:\  \       /:/  /                 //
//                      \:\__\     /:/  /        /:/  /       \:\__\        \:\__\     /:/  /                  //
//                       \/__/     \/__/         \/__/         \/__/         \/__/     \/__/                   //
//                                                                                                             //
//    Minds, bodies and external triggers.                                                                     //
//    Marbelous Minds explores people's lives, who they are, and why.                                          //
//    Is the person outside us the same as the person we are inside?                                           //
//    How many masks do we have and what caused them?                                                          //
//    Most of us have to live the realities that are imposed on us in order to adapt to the outside world.     //
//    But who are we actually? Why didn't we have masks when we were little kids?                              //
//    These are questions we ask ourselves every day. Maybe you can find yourself in Marbelous Minds.          //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("Marbelous Minds", "MM") {}
}
