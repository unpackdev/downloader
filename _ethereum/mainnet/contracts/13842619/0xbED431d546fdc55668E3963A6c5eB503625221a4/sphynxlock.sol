// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract SphynxLock is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 public staticFee;
    uint256 public staticLPFee;
    uint256 public performanceFee = 0; // 0%
    address payable public feeWallet;
    uint256 public currentLockId = 0;
    mapping(uint256 => uint256) public lockTimes;
    mapping(uint256 => uint256) public startTimes;
    mapping(uint256 => uint256) public vestingPeriods;
    mapping(uint256 => uint256) public lockedBalances;
    mapping(uint256 => uint256) public withdrawBalances;
    mapping(uint256 => address) public lockedTokens;
    mapping(uint256 => address) public lockedOwners;

    event LockCreated(
        uint256 lockId,
        uint256 lockTime,
        uint256 lockedBalance,
        address lockedToken
    );

    constructor(uint256 _staticFee) {
        staticFee = _staticFee;
        feeWallet = payable(msg.sender);
    }

    function updateStaticFee(uint256 _staticFee) external onlyOwner {
        staticFee = _staticFee;
    }

    function updateFeeWallet(address _feewallet) external onlyOwner {
        feeWallet = payable(_feewallet);
    }

    function updateStaticLPFee(uint256 _staticLPFee) external onlyOwner {
        staticLPFee = _staticLPFee;
    }

    function updatePerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
    }

    function createLock(
        uint256 _lockTime,
        uint256 _vestingPeriods,
        uint256 _lockedBalance,
        address _lockedToken,
        bool _isLP
    ) external payable nonReentrant {
        require(_lockTime > block.timestamp, "invalid-time");
        uint256 serviceFee = _isLP ? staticLPFee : staticFee;
        require(msg.value >= serviceFee, "insuffient-fee");
        feeWallet.transfer(msg.value);
        lockTimes[currentLockId] = _lockTime;
        startTimes[currentLockId] = block.timestamp;
        if(_isLP) {
            lockedBalances[currentLockId] = _lockedBalance;
        } else {
            lockedBalances[currentLockId] = _lockedBalance
            .mul(10000 - performanceFee)
            .div(10000);
        }
        lockedOwners[currentLockId] = msg.sender;
        vestingPeriods[currentLockId] = _vestingPeriods;
        lockedTokens[currentLockId] = _lockedToken;
        IERC20 token = IERC20(_lockedToken);
        uint256 originBalance = token.balanceOf(address(this));
        token.safeTransferFrom(
            msg.sender,
            address(this),
            _lockedBalance
        );
        uint256 afterBalance = token.balanceOf(address(this));
        require(
            afterBalance.sub(originBalance) == _lockedBalance,
            "not-equal-amount"
        );
        if(!_isLP) {
            token.safeTransfer(
            feeWallet,
            _lockedBalance.mul(performanceFee).div(10000)
        );
        }
        emit LockCreated(
            currentLockId,
            _lockTime,
            _lockedBalance,
            _lockedToken
        );
        currentLockId = currentLockId.add(1);
    }

    function withdrawToken(uint256 _lockId) external nonReentrant {
        require(msg.sender == lockedOwners[_lockId], "not-owner");
        uint256 step = (block.timestamp.sub(startTimes[_lockId]))
            .mul(vestingPeriods[_lockId])
            .div((lockTimes[_lockId].sub(startTimes[_lockId])));
        uint256 availableBalance;
        if (block.timestamp > lockTimes[_lockId]) {
            availableBalance = lockedBalances[_lockId];
        } else {
            availableBalance = lockedBalances[_lockId].mul(step).div(
                vestingPeriods[_lockId]
            );
        }
        availableBalance = availableBalance.sub(withdrawBalances[_lockId]);
        withdrawBalances[_lockId] = withdrawBalances[_lockId].add(
            availableBalance
        );
        IERC20 token = IERC20(lockedTokens[_lockId]);
        token.safeTransfer(
            msg.sender,
            availableBalance
        );
    }

    function getAvailableBalance(uint256 _lockId)
        external
        view
        returns (uint256 availableBalance)
    {
        uint256 step = (block.timestamp.sub(startTimes[_lockId]))
            .mul(vestingPeriods[_lockId])
            .div((lockTimes[_lockId].sub(startTimes[_lockId])));
        if (block.timestamp > lockTimes[_lockId]) {
            availableBalance = lockedBalances[_lockId];
        } else {
            availableBalance = lockedBalances[_lockId].mul(step).div(
                vestingPeriods[_lockId]
            );
        }
        availableBalance = availableBalance.sub(withdrawBalances[_lockId]);
    }
}
