// SPDX-License-Identifier: MIT

/// @title The Seeker by Karborn
/// @author transientlabs.xyz

/*//////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//    !!KARBORNXTRANSIENTLABS.1930-2023.SELECTALLSAVEANDEXI(S)T.LONDONSCENE!:)    //
//    <<BEWARETHEMEDUSA!SHEWILLPETRIFYYOU?!BUILTONTHECOLLECTORSCHOICECONTRACT>>   //
//    WELCOMETOTHESEEKER.......................................................   //
//                                                                                //
//////////////////////////////////////////////////////////////////////////////////*/

pragma solidity 0.8.19;

import "./CollectorsChoice.sol";

contract TheSeeker is CollectorsChoice {

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) CollectorsChoice(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        name,
        symbol,
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        initOwner,
        admins,
        enableStory,
        blockListRegistry
    ) {}
}