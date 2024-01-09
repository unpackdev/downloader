// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

import "./TokenERC20.sol";
import "./StakingPoolFactory.sol";
import "./RewardManager.sol";

contract StakingPool is Context, Ownable, ReentrancyGuard {

    mapping (address => uint256) private stakes;
    mapping (address => uint256) private stakeTimes;

    uint256 public stakedTotal;
    uint256 public maturityDays;
    uint256 public launchTime;
    uint256 public closingTime;
    uint256 public poolSize;
    uint256 public poolApy;
    TokenERC20 public tokenERC20;
    StakingPoolFactory public poolFactory;
    RewardManager public rewardManager;

    uint256 interval = 86400;

    event Staked(address indexed _staker, uint256 _requestedAmount, uint256 _stakedAmount);
    event PaidOut(address indexed _staker, uint256 _reward);
    event Refunded(address indexed _staker, uint256 _amount);

    constructor (
        TokenERC20 _tokenERC20,
        StakingPoolFactory _poolFactory,
        RewardManager _rewardManager,
        uint256 _maturityDays,
        uint256 _launchTime,
        uint256 _closingTime,
        uint256 _poolSize,
        uint256 _poolApy
    ) {
        tokenERC20 = _tokenERC20;
        poolFactory = _poolFactory;
        rewardManager = _rewardManager;

        require(_maturityDays > 0, "Staking Pool: zero maturity days");

        maturityDays = _maturityDays;

        require(_launchTime > 0, "Staking Pool: zero staking start time");
        if (_launchTime < block.timestamp) {
            launchTime = block.timestamp;
        } else {
            launchTime = _launchTime;
        }

        require(_closingTime > _launchTime, "Staking Pool: closing time must be after launch time");
        closingTime = _closingTime;

        require(_poolSize > 0, "Staking Pool: pool size must be positive");
        poolSize = _poolSize;

        require(_poolApy > 0, "Staking Pool: pool apy must be positive");
        poolApy = _poolApy;
    }

    function stakeOf(address account) external view returns (uint256) {
        return stakes[account];
    }

    function stakeTimeOf(address account) external view returns (uint256) {
        return stakeTimes[account];
    }

    function getRewards(address account) external view returns (uint256) {
        if (block.timestamp > stakeTimes[account] + (maturityDays * interval)) {
            return stakes[account] * poolApy * maturityDays / 36000;
        }

        return 0;
    }

    function stake(uint256 amount)
        external
        _positive(amount)
        _realAddress(_msgSender())
        _after(launchTime)
        _before(closingTime)
        _hasAllowance(_msgSender(), amount)
        returns (bool)
    {
        address staker = _msgSender();
        uint256 remaining = amount;
        if (remaining > (poolSize - stakedTotal)) {
            remaining = poolSize - stakedTotal;
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal is only modified in this method during the staking period
        require(remaining > 0, "Staking Pool: Pool is filled");
        require((remaining + stakedTotal) <= poolSize, "Staking Pool: this will increase staking amount pass the cap");

        if (!_payMe(staker, remaining)) {
            return false;
        }
        emit Staked(staker, amount, remaining);

        if (remaining < amount) {
            // Return the unstaked amount to sender (from allowance)
            uint256 refund = amount - remaining;
            if (_payTo(staker, staker, refund)) {
                emit Refunded(staker, refund);
            }
        }

        // Transfer is completed
        stakedTotal = stakedTotal + remaining;
        stakes[staker] = stakes[staker] + remaining;
        stakeTimes[staker] = block.timestamp;

        return true;
    }

    function withdraw()
        external
        nonReentrant
        _realAddress(_msgSender())
    {
        address staker = _msgSender();

        require(stakes[staker] > 0, "Zero staked Mixsome");

        uint256 amount = stakes[staker];
        stakes[staker] = 0;
        _payDirect(staker, amount);

        if (block.timestamp > stakeTimes[staker] + (maturityDays * interval)) {
            uint256 reward = amount * poolApy * maturityDays / 36000;
            rewardManager.rewardUser(staker, reward);
            PaidOut(staker, reward);
        }
    }

    function _payMe(address payer, uint256 amount)
        private
        returns (bool) 
    {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(address allower, address receiver, uint256 amount)
        _hasAllowance(allower, amount)
        private
        returns (bool) 
    {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        return tokenERC20.transferFrom(allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount)
        private
        _positive(amount)
        returns (bool) 
    {
        return tokenERC20.transfer(to, amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Staking Pool: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "Staking Pool: negative amount");
        _;
    }

    modifier _after(uint eventTime) {
        require(block.timestamp >= eventTime, "Staking Pool: bad timing for the request");
        _;
    }

    modifier _before(uint eventTime) {
        require(block.timestamp < eventTime, "Staking Pool: bad timing for the request");
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        uint256 ourAllowance = tokenERC20.allowance(allower, address(this));
        require(amount <= ourAllowance, "Staking Pool: Make sure to add enough allowance");
        _;
    }
}