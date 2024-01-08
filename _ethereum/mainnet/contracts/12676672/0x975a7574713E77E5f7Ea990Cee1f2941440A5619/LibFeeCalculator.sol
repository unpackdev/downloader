// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./LibGovernance.sol";

library LibFeeCalculator {
    using SafeMath for uint256;
    bytes32 constant STORAGE_POSITION = keccak256("fee.calculator.storage");

    struct Storage {
        bool initialized;

        // The current service fee
        uint256 serviceFee;

        // Total fees accrued since contract deployment
        uint256 feesAccrued;

        // Total fees accrued up to the last point a member claimed rewards
        uint256 previousAccrued;

        // Accumulates rewards on a per-member basis
        uint256 accumulator;

        // Total rewards claimed per member
        mapping(address => uint256) claimedRewardsPerAccount; 
    }

    function feeCalculatorStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice addNewMember Sets the initial claimed rewards for new members
     * @param _account The address of the new member
     */
    function addNewMember(address _account) internal {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();
        uint256 amount = fcs.feesAccrued.sub(fcs.previousAccrued).div(LibGovernance.membersCount());

        fcs.previousAccrued = fcs.feesAccrued;
        fcs.accumulator = fcs.accumulator.add(amount);
        fcs.claimedRewardsPerAccount[_account] = fcs.accumulator;
    }

    /**
     * @notice claimReward Make calculations based on fee distribution and returns the claimable amount
     * @param _claimer The address of the claimer
     */
    function claimReward(address _claimer)
        internal
        returns (uint256)
    {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();
        uint256 amount = fcs.feesAccrued.sub(fcs.previousAccrued).div(LibGovernance.membersCount());

        fcs.previousAccrued = fcs.feesAccrued;
        fcs.accumulator = fcs.accumulator.add(amount);

        uint256 claimableAmount = fcs.accumulator.sub(fcs.claimedRewardsPerAccount[_claimer]);

        fcs.claimedRewardsPerAccount[_claimer] = fcs.accumulator;

        return claimableAmount;
    }

    /**
     * @notice Distributes rewards among members
     */
    function distributeRewards() internal {
        LibFeeCalculator.Storage storage fcs = feeCalculatorStorage();
        fcs.feesAccrued = fcs.feesAccrued.add(fcs.serviceFee);
    }
}