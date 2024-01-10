
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crowns All Around
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//    _________                                       .___    //
//    \_   ___ \_______  ______  _  ______   ____   __| _/    //
//    /    \  \/\_  __ \/  _ \ \/ \/ /    \_/ __ \ / __ |     //
//    \     \____|  | \(  <_> )     /   |  \  ___// /_/ |     //
//     \______  /|__|   \____/ \/\_/|___|  /\___  >____ |     //
//            \/                         \/     \/     \/     //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract CRWNS is ERC721Creator {
    constructor() ERC721Creator("Crowns All Around", "CRWNS") {}
}
