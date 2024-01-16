// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Clones.sol";
import "./VivCrowfundingClonable.sol";

/**
 * Viv Guarantee Clone Factory
 */
contract VivCrowfundingCloneFactory is Ownable {
    using Clones for address;

    VivCrowfundingClonable[] _vivCrowfundings;

    event VivCrowfundingCreated(VivCrowfundingClonable vivCrowfunding);

    /**
     * Clone ETH Viv Guarantee Contract
     */
    function createVivCrowfunding(
        address libraryAddress,
        address platform,
        uint256 feeRate,
        address token
    ) external returns (VivCrowfundingClonable) {
        VivCrowfundingClonable vivCrowfunding = VivCrowfundingClonable(payable(libraryAddress.clone()));
        vivCrowfunding.init(msg.sender, platform, feeRate, token);
        _vivCrowfundings.push(vivCrowfunding);
        emit VivCrowfundingCreated(vivCrowfunding);
        return vivCrowfunding;
    }

    /**
     * Get all clone eth contracts
     */
    function getVivCrowfunding() external view returns (VivCrowfundingClonable[] memory) {
        return _vivCrowfundings;
    }
}
