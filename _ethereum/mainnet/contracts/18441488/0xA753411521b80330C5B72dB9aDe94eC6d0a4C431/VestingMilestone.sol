//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./BaseMilestone.sol";

contract VestingMilestone is BaseMilestone {
    using SafeERC20 for IERC20;

    //
    /**
    @notice Construct the contract, taking the ERC20 token to be vested as the parameter.

     */
    constructor(
        IERC20 _tokenAddress,
        uint256 _allocation,
        InputMilestone[] memory _milestones,
        address[] memory _recipients
    ) {
        require(address(_tokenAddress) != address(0), "INVALID_ADDRESS");
        tokenAddress = _tokenAddress;
        recipients = _recipients;
        allocation = _allocation;

        super.initializeMilestones(_milestones);
    }

    /**
    @notice Calculate the amount vested for a given _recipient at a reference timestamp.
    @param _recipient - The recipient address
    @param _milestoneIndex - The index of Milestone
    @param _referenceTs - The timestamp at which we want to calculate the vested amount.
    */
    function vestedAmount(
        address _recipient,
        uint256 _milestoneIndex,
        uint256 _referenceTs
    ) public view hasMilestone(_recipient, _milestoneIndex) returns (uint256) {
        Milestone memory milestone = milestones[_recipient][_milestoneIndex];
        if (milestone.startTime == 0) {
            return 0;
        }

        // Check if this time is over vesting end time
        if (_referenceTs > milestone.startTime + milestone.period) {
            return milestone.allocation;
        }

        if (_referenceTs > milestone.startTime) {
            uint256 currentVestingDurationSecs = _referenceTs -
                milestone.startTime; // How long since the start

            uint256 intervals = currentVestingDurationSecs /
                milestone.releaseIntervalSecs;
            uint256 amountPerInterval = (milestone.releaseIntervalSecs *
                milestone.allocation) / milestone.period;

            return amountPerInterval * intervals;
        }

        return 0;
    }

    /**
    @notice Calculate the total vested at the end of the schedule, by simply feeding in the end timestamp to the function above.
    @dev This fn is somewhat superfluous, should probably be removed.
     */
    function finalVestedAmount(
        address _recipient,
        uint256 _milestoneIndex
    ) public view returns (uint256) {
        return milestones[_recipient][_milestoneIndex].allocation;
    }

    /**
    @notice Calculates how much can we claim, by subtracting the already withdrawn amount from the vestedAmount at this moment.
    @param _recipient the address of the recipient.
    @param _milestoneIndex the index of milestones.
    */
    function claimableAmount(
        address _recipient,
        uint256 _milestoneIndex
    ) public view returns (uint256) {
        return
            vestedAmount(_recipient, _milestoneIndex, block.timestamp) -
            milestones[_recipient][_milestoneIndex].withdrawnAmount;
    }

    /**
    @notice Withdraw the full claimable balance.
    @param _milestoneIndex the index of milestones.
    @dev hasActiveClaim throws off anyone without a claim.
     */
    function withdraw(
        uint256 _milestoneIndex
    )
        external
        hasMilestone(_msgSender(), _milestoneIndex)
        onlyCompleted(_msgSender(), _milestoneIndex)
        nonReentrant
    {
        Milestone storage milestone = milestones[_msgSender()][_milestoneIndex];
        // we can use block.timestamp directly here as reference TS, as the function itself will make sure to cap it to endTimestamp
        uint256 allowance = vestedAmount(
            _msgSender(),
            _milestoneIndex,
            block.timestamp
        );

        // Make sure we didn't already withdraw more that we're allowed.
        require(allowance > milestone.withdrawnAmount, "NOTHING_TO_WITHDRAW");

        // Calculate how much can we withdraw (equivalent to the above inequality)
        uint256 amountRemaining = allowance - milestone.withdrawnAmount;

        milestone.withdrawnAmount = allowance;
        totalWithdrawnAmount += amountRemaining;

        tokenAddress.safeTransfer(_msgSender(), amountRemaining);

        // Let withdrawal known to everyone.
        emit Claimed(_msgSender(), amountRemaining);
    }
}
