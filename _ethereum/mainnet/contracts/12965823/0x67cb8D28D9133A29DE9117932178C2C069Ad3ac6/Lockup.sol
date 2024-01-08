// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TwoStageOwnable.sol";

contract Lockup is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct DepositData {
        uint256 amount;
        uint256 withdrawn;
        uint256 depositedAt;
        uint256 lockupEndsAt;
        uint256 unlockEndsAt;
    }

    IERC20 public token;

    uint256 private _unlockIntervalDuration;
    uint256 private _lockupDuration;
    uint256 private _unlockDuration;
    uint256 private _unlockIntervalsCount;
    uint256 private _totalDeposit;
    DepositData[] private _deposits;

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function unlockIntervalsCount() public view returns (uint256) {
        return _unlockIntervalsCount;
    }

    function lockupDuration() public view returns (uint256) {
        return _lockupDuration;
    }

    function totalDeposit() public view returns (uint256) {
        return _totalDeposit;
    }

    function unlockDuration() public view returns (uint256) {
        return _unlockDuration;
    }

    function availableToWithdraw(uint256 id) public view returns (uint256 amountToWithdraw) {
        DepositData storage deposit = _getDeposit(id);
        uint256 timestamp = getTimestamp();
        if (timestamp >= deposit.lockupEndsAt) {
            uint256 pastIntervalsCount = timestamp.sub(deposit.lockupEndsAt).div(_unlockIntervalDuration);
            amountToWithdraw = deposit.amount.mul(pastIntervalsCount).div(_unlockIntervalsCount);
            if (deposit.amount < amountToWithdraw) {
                amountToWithdraw = deposit.amount;
            }
            amountToWithdraw = amountToWithdraw.sub(deposit.withdrawn);
        }
    }

    function getDeposit(uint256 id) public view returns (DepositData memory) {
        return _getDeposit(id);
    }

    function getDeposits(
        uint256 offset,
        uint256 limit
    ) public view returns (DepositData[] memory depositData) {
        uint256 depositsLength = _deposits.length;
        if (offset >= depositsLength) return new DepositData[](0);
        uint256 to = offset.add(limit);
        if (depositsLength < to) to = depositsLength;
        depositData = new DepositData[](to - offset);
        for (uint256 i = 0; i < depositData.length; i++) depositData[i] = _deposits[offset + i];
    }

    function getDepositsCount() public view returns (uint256) {
        return _deposits.length;
    }

    event Deposited(address indexed account, uint256 depositId, uint256 amount);
    event Withdrawn(address indexed account, uint256 depositId, uint256 amount);

    constructor(
        address owner_,
        IERC20 token_,
        uint256 lockupDuration_,
        uint256 unlockDuration_,
        uint256 unlockIntervalsCount_
    ) public TwoStageOwnable(owner_) {
        require(lockupDuration_ > 0, "LockupDuration not positive");
        require(unlockDuration_ > 0, "UnlockDuration not positive");
        require(unlockIntervalsCount_ > 0, "UnlockIntervalsCount not positive");
        token = token_;
        _lockupDuration = lockupDuration_ * 1 weeks;
        _unlockDuration = unlockDuration_ * 1 weeks;
        _unlockIntervalsCount = unlockIntervalsCount_;
        _unlockIntervalDuration = _unlockDuration.div(unlockIntervalsCount_);
    }

    function deposit(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        uint256 timestamp = getTimestamp();
        uint256 depositId = _deposits.length;
        _totalDeposit = _totalDeposit.add(amount);
        _deposits.push();
        DepositData storage deposit_ = _deposits[depositId];
        deposit_.amount = amount;
        deposit_.depositedAt = timestamp;
        deposit_.lockupEndsAt = timestamp.add(_lockupDuration);
        deposit_.unlockEndsAt = _unlockDuration.add(deposit_.lockupEndsAt);
        token.safeTransferFrom(caller, address(this), amount);
        emit Deposited(caller, depositId, amount);
        return true;
    }

    function withdraw(uint256 id, uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        require(amount <= availableToWithdraw(id), "Not enough available tokens");
        _totalDeposit = _totalDeposit.sub(amount);
        DepositData storage deposit_ = _deposits[id];
        deposit_.withdrawn = deposit_.withdrawn.add(amount);
        token.safeTransfer(caller, amount);
        emit Withdrawn(caller, id, amount);
        return true;
    }

    function _getDeposit(uint256 id) internal view returns (DepositData storage) {
        require(id < _deposits.length, "Invalid deposit id");
        return _deposits[id];
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount not positive");
        _;
    }
}
