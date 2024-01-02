// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./DividendTracker.sol";
import "./SafeMath.sol";

contract Staking is DividendTracker, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public immutable STAKING_TOKEN;

    mapping(address => uint256) public holderUnlockTime;
    uint256 public lockDuration;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _lockTimeInDays
    ) Ownable(msg.sender) DividendTracker(_rewardToken) {
        require(_stakingToken != address(0), "ERR_ZERO_ADDRESS");

        STAKING_TOKEN = IERC20(_stakingToken);

        lockDuration = _lockTimeInDays * 1 days;
    }


    function changeLockDuration(uint256 _newNoOfDays) external onlyOwner {
        
        lockDuration = _newNoOfDays;
    }

    // Stake primary tokens
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "ERR_0_AMOUNT");

        if (holderUnlockTime[msg.sender] == 0) {
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        uint256 userAmount = holderBalance[msg.sender];

        uint256 amountTransferred = 0;

        uint256 initialBalance = STAKING_TOKEN.balanceOf(address(this));
        STAKING_TOKEN.transferFrom(address(msg.sender), address(this), _amount);
        amountTransferred =
            STAKING_TOKEN.balanceOf(address(this)) -
            initialBalance;

        setBalance(msg.sender, userAmount + amountTransferred);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw primary tokens
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "ERR_0_STAKE");
        uint256 userAmount = holderBalance[msg.sender];
        require(_amount <= userAmount, "ERR_NOT_ENOUGH_TOKENS");
        require(
            holderUnlockTime[msg.sender] <= block.timestamp,
            "ERR_LOCK_PERIOD_NOT_OVER"
        );

        STAKING_TOKEN.transfer(address(msg.sender), _amount);

        setBalance(msg.sender, userAmount - _amount);

        if (userAmount > 0) {
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            holderUnlockTime[msg.sender] = 0;
        }

        emit Withdraw(msg.sender, _amount);
    }

    function withdrawAll() public nonReentrant {
        uint256 userAmount = holderBalance[msg.sender];
        require(userAmount > 0, "ERR_0_STAKE");
        require(
            holderUnlockTime[msg.sender] <= block.timestamp,
            "ERR_LOCK_PERIOD_NOT_OVER"
        );

        STAKING_TOKEN.transfer(address(msg.sender), userAmount);

        setBalance(msg.sender, 0);
        holderUnlockTime[msg.sender] = 0;

        emit Withdraw(msg.sender, userAmount);
    }

    function claim() external nonReentrant {
        processAccount(msg.sender, false);
    }

    // Distribute Reward
    function distributeDividends(uint256 _amount) external onlyOwner {
        require(_amount > 0, "ERR_0_REWARD_AMOUNT");
        require(totalBalance > 0, "ERR_TOTAL_BALANCE_0");

        IERC20(REWARD_TOKEN).transferFrom((msg.sender), address(this), _amount);
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (_amount).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, _amount);

        totalDividendsDistributed = totalDividendsDistributed.add(_amount);
    }
}
