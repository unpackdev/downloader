// SPDX-License-Identifier: MIT

/// @title Reimagined Spaces // Childhood Revisions
/// @author transientlabs.xyz

/*////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//    *██▄   ╓Æ╗▌  ,▄████▓▄    ▌¥▄          ▓▄     j██▓    ▌¥▌ ███████▄j██▄  ▄██▀▀▄     //
//     └███▄▓╙▄▀  ███▀▀▀▀███▄  ▌ ▌         ███▄    ▐████▄  ▌ ▌ ▀▀█▀█▀▀▀▐██▌ ███▀▀▄▄▌    //
//       ▀████   ███      ███  ▌ ▌        █████▌   ▐▌▐████ ▌ ▌   █ ╫   ▐██▌ ▀████▄      //
//        ███    █▀█─     █▀█  ▌ ▌       ███┬╝██▌  ▐▌▐▌╙███▌ ▌   █ ╫   ▐█▀▌   ╨▀███▌    //
//        ███     ▀▄╙▀╪╪▀▀,▓╙  ▌ █████▌ █ █████▄╙▌ ▐▌▐▌  ▀███▌   █ ╫   ▐▌▐▌ █╙▀╪███▌    //
//        ╙▀▀       ╙▀▀▀▀▀┴    ▀▀▀▀▀▀▀▀╨▀▀>    ╙Σ▀\ ▀▀Γ   ╙▀▀▀   ╨Σ▀    ▀▀Γ  ╙▀▀▀▀└     //
//    ---                                                                               //
//    asciiart.club                                                                     //
//                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract ReimaginedSpacesChildhoodRevisions is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Reimagined Spaces // Childhood Revisions",
        "RSCR",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
