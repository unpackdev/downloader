// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ConsiderationStructs.sol";
import "./RedeemablesStructs.sol";

interface IRedemptionMintable {
    function mintRedemption(
        uint256 campaignId,
        address recipient,
        ConsiderationItem[] calldata consideration,
        TraitRedemption[] calldata traitRedemptions
    ) external;
}
