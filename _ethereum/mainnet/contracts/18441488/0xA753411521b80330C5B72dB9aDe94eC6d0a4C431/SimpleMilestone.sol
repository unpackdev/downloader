//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./BaseMilestone.sol";

contract SimpleMilestone is BaseMilestone {
    using SafeERC20 for IERC20;

    /**
    @notice Construct the contract.
    @param _tokenAddress - the address of the claim token.
    @param _allocation - the allocation amount for this milestone.
    @param _allcationPercents - the allocation percents
    @param _recipients - the addresses for which we fetch the claim.
    @dev Factory contract will deposit the token when creating this contract.
    // This is created by Factory contract and Safe wallet can be used, 
    // so factory contract should pass address which will be the owner of this contract.
     */
    constructor(
        IERC20 _tokenAddress,
        uint256 _allocation,
        uint256[] memory _allcationPercents,
        address[] memory _recipients
    ) {
        recipients = _recipients;
        tokenAddress = _tokenAddress;
        allocation = _allocation;

        super.initializeAllocations(_allcationPercents);
    }

    /**
    @notice Calculates how much recipient can claim.
    */
    function claimableAmount(
        address _recipient,
        uint256 _milestoneIndex
    ) public view returns (uint256) {
        Milestone memory milestone = milestones[_recipient][_milestoneIndex];
        if (milestone.startTime == 0 || milestone.isWithdrawn) {
            return 0;
        } else {
            return milestone.allocation;
        }
    }

    /**
    @notice Only recipient can claim when it's completed.
    @dev Withdraw all tokens.
     */
    function withdraw(
        uint256 _milestoneIndex
    )
        public
        hasMilestone(_msgSender(), _milestoneIndex)
        onlyCompleted(_msgSender(), _milestoneIndex)
        nonReentrant
    {
        Milestone storage milestone = milestones[_msgSender()][_milestoneIndex];
        require(!milestone.isWithdrawn, "ALREADY_WITHDRAWED");

        milestone.isWithdrawn = true;
        totalWithdrawnAmount += milestone.allocation;
        tokenAddress.safeTransfer(_msgSender(), milestone.allocation);

        // Let withdrawal known to everyone.
        emit Claimed(_msgSender(), milestone.allocation);
    }
}
