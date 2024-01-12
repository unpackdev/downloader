// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (finance/VestingWallet.sol)
pragma solidity 0.8.5;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Math.sol";

import "./LinearCheckpointVesting.sol";

/**
 * @title LinearCheckpointDualBeneficiaryVestingWallet
 * @dev This is a fork of the OpenZeppelin {VestingWallet} smart contract that splits to two addresses when releasing.
 *  This can't be implemented as an extension to {VestingWallet} as the release() function encapsulates access to the
 *  released/erc20Released private fields and controls the sending.
 *
 * Since this is used for a special case that we need it removes the ability to vest for multiple tokens and ETH to
 * reduce complexity.
 *
 * The vesting schedule is implemented via {LinearCheckpointVesting}
 */
contract LinearCheckpointDualBeneficiaryVestingWallet is Context, LinearCheckpointVesting {
    event ERC20Released(address indexed token, uint256 amount);

    address private immutable _tokenAddress;
    uint256 private _released;
    address private immutable _beneficiary;

    address private immutable _secondaryBeneficiary;
    uint64 private immutable _percentageSplit;

    /**
     * @dev Set the beneficiary, secondary beneficiary, percentage split, checkpoints and token address of the
     * vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        address secondaryBeneficiaryAddress,
        uint64 beneficiaryPercentageSplit,
        uint64[] memory checkpoints,
        address tokenAddress
    ) LinearCheckpointVesting(checkpoints) {
        require(beneficiaryAddress != address(0),
            "LinearCheckpointDualBeneficiaryVestingWallet: beneficiary is zero address");
        require(secondaryBeneficiaryAddress != address(0),
            "LinearCheckpointDualBeneficiaryVestingWallet: secondaryBeneficiary is zero address");
        require(beneficiaryPercentageSplit > 0 && beneficiaryPercentageSplit < 100,
            "LinearCheckpointDualBeneficiaryVestingWallet: percentageSplit is not between 1 and 99");
        require(tokenAddress != address(0),
            "LinearCheckpointDualBeneficiaryVestingWallet: tokenAddress is zero address");
        _beneficiary = beneficiaryAddress;
        _secondaryBeneficiary = secondaryBeneficiaryAddress;
        _percentageSplit = beneficiaryPercentageSplit;
        _tokenAddress = tokenAddress;
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() external view returns (uint256) {
        return checkpoints()[0];
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() external view returns (uint256) {
        uint64[] memory _checkpoints = checkpoints();
        return _checkpoints[_checkpoints.length - 1] - _checkpoints[0];
    }

    /**
     * @dev Getter for the secondary beneficiary
     */
    function secondaryBeneficiary() external view returns (address) {
        return _secondaryBeneficiary;
    }

    /**
     * @dev Getter for the percentage split
     */
    function percentageSplit() external view returns (uint64) {
        return _percentageSplit;
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() external {
        uint256 releasable = vestedAmount(uint64(block.timestamp)) - released();
        _released += releasable;
        uint256 mainBeneficiaryAmount = (releasable * _percentageSplit) / 100;
        uint256 secondaryBeneficiaryAmount = releasable - mainBeneficiaryAmount;
        emit ERC20Released(_tokenAddress, releasable);
        SafeERC20.safeTransfer(IERC20(_tokenAddress), _beneficiary, mainBeneficiaryAmount);
        SafeERC20.safeTransfer(IERC20(_tokenAddress), _secondaryBeneficiary, secondaryBeneficiaryAmount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        return _vestingSchedule(IERC20(_tokenAddress).balanceOf(address(this)) + released(), timestamp);
    }

    /**
     * @dev Delegates to the {CheckpointVesting} implementation
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view returns (uint256) {
        return LinearCheckpointVesting.checkpointVestingSchedule(totalAllocation, timestamp);
    }
}
