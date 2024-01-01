//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./errors.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Locker {
    using SafeERC20 for IERC20;
    mapping(address => mapping(address => Deposit)) public deposits;

    struct Deposit {
        address owner;
        uint256 amount;
        uint64 lockEndTime;
    }

    event TokensDeposited(address indexed owner, uint256 amount, address token);
    event TokensWithdrawn(address indexed owner, uint256 amount, address token);

    constructor() {}

    modifier onlyAfterLockPeriod(address _tokenAddress) {
        IERC20 _token = IERC20(_tokenAddress);
        Deposit storage deposit = deposits[_tokenAddress][msg.sender];
        if (deposit.lockEndTime == 0) {
            revert Locker_NoDepositForToken();
        }
        if (block.timestamp < deposit.lockEndTime) {
            revert Locker_LockPeriodNotEnded();
        }
        _;
    }

    function depositTokens(address _tokenAddress, uint256 _amount, uint8 _lockDurationInYears)
    external
    {
        if (_amount == 0) {
            revert Locker_WrongInputUint();
        }
        if (_tokenAddress == address(0)) {
            revert Locker_WrongInputAddress();
        }
        if (_lockDurationInYears == 0) {
            revert Locker_WrongLockDuration();
        }

        uint64 _lockDuration = uint64(_lockDurationInYears) * 365 days;
        uint64 _lockEndTime = uint64(block.timestamp) + _lockDuration;

        IERC20 _token = IERC20(_tokenAddress);
        SafeERC20.safeTransferFrom(_token, msg.sender, address(this), _amount);

        Deposit storage deposit = deposits[_tokenAddress][msg.sender];
        if (deposit.amount > 0) {
            deposit.amount += _amount;
        } else {
            deposits[_tokenAddress][msg.sender] = Deposit(msg.sender, _amount, _lockEndTime);
        }

        emit TokensDeposited(msg.sender, _amount, _tokenAddress);
    }

    function withdrawTokens(address _tokenAddress)
    external
    onlyAfterLockPeriod(_tokenAddress)
    {
        Deposit storage deposit = deposits[_tokenAddress][msg.sender];
        if (_tokenAddress == address(0)) {
            revert Locker_WrongInputAddress();
        }
        if (deposit.amount == 0) {
            revert Locker_NoDepositForToken();
        }

        uint256 _amount = deposit.amount;
        deposit.amount = 0;
        deposit.lockEndTime = 0;

        IERC20 _token = IERC20(_tokenAddress);
        SafeERC20.safeTransfer(_token, msg.sender, _amount);

        emit TokensWithdrawn(msg.sender, _amount, _tokenAddress);
    }

    function getBalanceOf(address _tokenAddress)
    public view
    returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getUnlockTime(address _tokenAddress, address _owner)
    public view
    returns (uint64)
    {
        Deposit storage deposit = deposits[_tokenAddress][_owner];
        if (deposit.amount == 0) {
            revert Locker_NoDepositForToken();
        }

        return deposit.lockEndTime;
    }

}