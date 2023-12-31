// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.8.18;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Staking.sol";

contract StakingFactory is Ownable {
    error ZeroAddress();
    error TimeIsZero();
    error AmountIsZero();
    error StartIsMoreOrEqualThanFinish(uint _startAt, uint _finishAt);
    error FeeNotPayed();
    error TransferFailed();
    error PercentageOutOfRange(uint _percentage);

    struct StakingContract {
        address addr;
        address stakingToken;
        address rewardsToken;
        uint maxAmountUserCanStake;
        uint startAt;
        uint finishAt;
    }

    address public feeReceiver;
    uint public creatorFee;

    StakingContract[] public stakingContracts;

    constructor(address _feeReceiver, uint _creatorFee) {
        if (_feeReceiver == address(0)) {
            revert ZeroAddress();
        }
        feeReceiver = _feeReceiver;
        creatorFee = _creatorFee;
    }

    function createStakePool(
        address _stakingToken,
        address _rewardsToken,
        address _emergencyWithdrawAddress,
        uint _amountToFund,
        uint _emergencyWithdrawPercentage,
        uint _maxAmountUserCanStake,
        uint _start,
        uint _finish
    ) public payable returns (address) {
        if (
            _stakingToken == address(0) ||
            _rewardsToken == address(0) ||
            _emergencyWithdrawAddress == address(0)
        ) {
            revert ZeroAddress();
        }

        if (_emergencyWithdrawPercentage > 10000) {
            revert PercentageOutOfRange(_emergencyWithdrawPercentage);
        }

        if (msg.value < creatorFee) {
            revert FeeNotPayed();
        }

        (bool success, ) = feeReceiver.call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        if (_amountToFund == 0) {
            revert AmountIsZero();
        }

        if (_start == 0 || _finish == 0) {
            revert TimeIsZero();
        }

        if (_start >= _finish) {
            revert StartIsMoreOrEqualThanFinish(_start, _finish);
        }

        Staking staking = new Staking(
            _stakingToken,
            _rewardsToken,
            _emergencyWithdrawAddress,
            _emergencyWithdrawPercentage,
            _maxAmountUserCanStake,
            _start,
            _finish
        );

        StakingContract memory stakingContract = StakingContract({
            addr: address(staking),
            stakingToken: _stakingToken,
            rewardsToken: _rewardsToken,
            maxAmountUserCanStake: _maxAmountUserCanStake,
            startAt: _start,
            finishAt: _finish
        });

        stakingContracts.push(stakingContract);
        IERC20(_rewardsToken).transferFrom(
            msg.sender,
            address(staking),
            _amountToFund
        );

        staking.notifyRewardAmount(_amountToFund);
        staking.transferOwnership(msg.sender);

        return address(staking);
    }

    function setFee(uint _newFee) external onlyOwner {
        creatorFee = _newFee;
    }

    function setFeeReceiver(address _newReceiver) external onlyOwner {
        if (_newReceiver == address(0)) {
            revert ZeroAddress();
        }

        feeReceiver = _newReceiver;
    }

    function getStakePools() public view returns (StakingContract[] memory) {
        return stakingContracts;
    }

    function getStakePoolsWithTotalSupply()
        public
        view
        returns (StakingContract[] memory, uint[] memory)
    {
        uint[] memory totalSupplies = new uint[](stakingContracts.length);
        for (uint i; i < stakingContracts.length; ) {
            totalSupplies[i] = Staking(stakingContracts[i].addr).totalSupply();
            unchecked {
                ++i;
            }
        }

        return (stakingContracts, totalSupplies);
    }
}
