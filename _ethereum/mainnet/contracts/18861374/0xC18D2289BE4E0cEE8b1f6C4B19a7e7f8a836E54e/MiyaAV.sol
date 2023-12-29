// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./AlignmentVault.sol";

/**
 * @title MiyaAV
 * @notice This contract implements overrides on AlignmentVault.sol to suit MiyaMaker's needs
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:devgithub https://github.com/Zodomo/MiyaMints
 * @custom:miyagithub https://github.com/miyamaker/MiyaMints
 */
contract MiyaAV is AlignmentVault {
    constructor() payable {}

    /**
     * @notice Override claimYield(address) to send 100% of yield to MiyaMints.sol
     * @param _recipient Unused parameter
     */
    function claimYield(address _recipient) public payable override {
        // Claim SLP rewards
        _NFTX_LIQUIDITY_STAKING.claimRewards(vaultId);
        // Determine yield amount
        uint256 yield = nftxInventory.balanceOf(address(this));
        // If no yield, end execution to save gas
        if (yield == 0) return;
        // Send all yield to MiyaAV's owner MiyaMints.sol, success isn't checked as it cannot fail
        nftxInventory.transfer(owner(), yield);
    }
    /**
     * @notice claimYield overload that doesn't require a recipient input
     */

    function claimYield() external payable {
        claimYield(address(this));
    }
}
