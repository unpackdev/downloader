// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRstStakingPool.sol";

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";

contract RstStakingPoolFunctions is AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using SafeERC20 for IERC20;

    IRstStakingPool public rstStakingPool;

    uint256 public constant REWARD_DECIMALS = 1000000;
    uint256 public constant BONUS_DECIMALS = 1000000000;
    uint256 public constant TOKEN_REWARD_DECIMALS = 10000000000000;

    uint256 public fullBonusCutoff;

    // Events
    event TokenRewardWithdrawn(uint256 amount);

    event TokensStaked(address payer, uint256 amount, uint256 timestamp);
    event TokensWithdrawn(address owner, uint256 amount, uint256 timestamp);

    event RainbowPointsBurned(address owner, uint256 amount);
    event RainbowPointsMinted(address owner, uint256 amount);

    event RewardWithdrawn(address owner, uint256 amount, uint256 timestamp);
    event RewardPoolAdded(
        uint256 _amount,
        uint256 _duration,
        uint256 timestamp
    );

    constructor(address _rstStakingPoolAddress, uint256 _fullBonusCutoff) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rstStakingPool = IRstStakingPool(_rstStakingPoolAddress);
        fullBonusCutoff = _fullBonusCutoff;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "not an owner"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "not a burner"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "not a minter"
        );
        _;
    }

    function balanceUpdate(address _owner) internal {
        IRstStakingPool.AccountRewardVars memory _accountRewardVars = rstStakingPool.accountRewardVars(_owner);
        IRstStakingPool.AccountVars memory _accountVars = rstStakingPool.accountVars(_owner);
        IRstStakingPool.GeneralRewardVars memory _generalRewardVars = rstStakingPool.generalRewardVars();

        // TokenReward rewards
        _generalRewardVars.tokenRewardPerTokenStored = uint64(
            tokenRewardPerToken()
        );
        _generalRewardVars.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (_owner != address(0)) {
            uint32 duration = uint32(block.timestamp) -
                _accountRewardVars.lastUpdated;
            uint128 rainbowReward = calculateReward(
                _owner,
                rstStakingPool.staked(_owner),
                duration,
                rstStakingPool.rewardRate(),
                true
            );

            _accountVars.rainbowBalance = _accountVars.rainbowBalance + rainbowReward;
            
            _accountRewardVars.lastUpdated = uint32(block.timestamp);
            _accountRewardVars.lastBonus = uint64(
                Math.min(
                    rstStakingPool.maxBonus(),
                    _accountRewardVars.lastBonus + rstStakingPool.bonusRate() * duration
                )
            );

            _accountRewardVars.tokenRewards = uint96(tokenRewardEarned(_owner));
            _accountRewardVars.tokenRewardPerTokenPaid = _generalRewardVars
                .tokenRewardPerTokenStored;
        }

        rstStakingPool.setAccountRewardVars(_owner, _accountRewardVars);
        rstStakingPool.setAccountVars(_owner, _accountVars);
        rstStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function setFullBonusCutoff(uint256 _fullBonusCutoff)
        external
        onlyOwner 
    {
        fullBonusCutoff = _fullBonusCutoff;
    }

    function getRewardByDuration(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint256) {
        return calculateReward(_owner, _amount, _duration, rstStakingPool.rewardRate(), true);
    }

    function getStaked(address _owner) public view returns (uint256) {
        return rstStakingPool.staked(_owner);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        uint256 reward = calculateReward(
            _owner,
            rstStakingPool.staked(_owner),
            block.timestamp - rstStakingPool.accountRewardVars(_owner).lastUpdated,
            rstStakingPool.rewardRate(),
            true
        );
        return rstStakingPool.accountVars(_owner).rainbowBalance + reward;
    }

    function getCurrentBonus(address _owner) public view returns (uint256) {
        IRstStakingPool.AccountRewardVars memory _accountRewardVars = rstStakingPool.accountRewardVars(_owner);

        if (rstStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - _accountRewardVars.lastUpdated;
        return
            Math.min(
                rstStakingPool.maxBonus(),
                _accountRewardVars.lastBonus + rstStakingPool.bonusRate() * duration
            );
    }

    function getCurrentAvgBonus(address _owner, uint256 _duration)
        public
        view
        returns (uint256)
    {
        IRstStakingPool.AccountRewardVars memory _accountRewardVars = rstStakingPool.accountRewardVars(_owner);

        if (rstStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 avgBonus;
        if (_accountRewardVars.lastBonus < rstStakingPool.maxBonus()) {
            uint256 durationTillMax = (rstStakingPool.maxBonus() -
                _accountRewardVars.lastBonus) / rstStakingPool.bonusRate();
            if (_duration > durationTillMax) {
                uint256 avgWeightedBonusTillMax = ((_accountRewardVars
                    .lastBonus + rstStakingPool.maxBonus()) * durationTillMax) / 2;
                uint256 weightedMaxBonus = rstStakingPool.maxBonus() *
                    (_duration - durationTillMax);

                avgBonus =
                    (avgWeightedBonusTillMax + weightedMaxBonus) /
                    _duration;
            } else {
                avgBonus =
                    (_accountRewardVars.lastBonus +
                        rstStakingPool.bonusRate() *
                        _duration +
                        _accountRewardVars.lastBonus) /
                    2;
            }
        } else {
            avgBonus = rstStakingPool.maxBonus();
        }
        return avgBonus;
    }

    function setReward(uint256 _rewardRate, uint256 _minRewardStake)
        external
        onlyOwner
    {
        rstStakingPool.setRewardRate(_rewardRate);
        rstStakingPool.setMinRewardStake(_minRewardStake);
    }

    function setBonus(uint256 _maxBonus, uint256 _bonusDuration)
        external
        onlyOwner
    {
        rstStakingPool.setMaxBonus(_maxBonus * BONUS_DECIMALS);
        rstStakingPool.setBonusDuration(_bonusDuration);
        rstStakingPool.setBonusRate(rstStakingPool.maxBonus() / _bonusDuration);
    }

    function stake(uint128 _amount)
        external
    {
        balanceUpdate(_msgSender());
        require(_amount > 0, "_amount is 0");

        IRstStakingPool.AccountRewardVars memory _accountRewardVars = rstStakingPool.accountRewardVars(_msgSender());
        
        uint256 currentStake = rstStakingPool.staked(_msgSender());
        rstStakingPool.stakeTokens(_msgSender(), _amount);

        if (block.timestamp <= fullBonusCutoff) {
            _accountRewardVars.lastBonus = uint64(rstStakingPool.maxBonus());
        } else {
            _accountRewardVars.lastBonus = uint64(
                (_accountRewardVars.lastBonus * currentStake) /
                    (currentStake + _amount)
            );
        }

        rstStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);

        emit TokensStaked(_msgSender(), _amount, block.timestamp);
    }

    function withdraw(uint128 _amount)
        external
    {
        balanceUpdate(_msgSender());
        rstStakingPool.withdrawTokens(_msgSender(), _amount);

        emit TokensWithdrawn(_msgSender(), _amount, block.timestamp);
    }

    function mint(address[] calldata _addresses, uint256[] calldata _points)
        external
        onlyMinter
    {
        IRstStakingPool.AccountVars memory _accountVars;

        for (uint256 i = 0; i < _addresses.length; i++) {
            _accountVars = rstStakingPool.accountVars(_addresses[i]);
            _accountVars.rainbowBalance = uint128(
                _accountVars.rainbowBalance + _points[i]
            );
            rstStakingPool.setAccountVars(_addresses[i], _accountVars);
            emit RainbowPointsMinted(_addresses[i], _points[i]);
        }
    }

    function burn(address _owner, uint256 _amount)
        external
        onlyBurner
    {
        balanceUpdate(_owner);
        IRstStakingPool.AccountVars memory _accountVars = rstStakingPool.accountVars(_owner);
        _accountVars.rainbowBalance = uint128(
            _accountVars.rainbowBalance - _amount
        );
        rstStakingPool.setAccountVars(_owner, _accountVars);

        emit RainbowPointsBurned(_owner, _amount);
    }

    function calculateReward(
        address _owner,
        uint256 _amount,
        uint256 _duration,
        uint256 _rewardRate,
        bool _addBonus
    ) private view returns (uint128) {
        uint256 reward = (_duration * _rewardRate * _amount) /
            (REWARD_DECIMALS * rstStakingPool.minRewardStake());

        return _addBonus ? calculateBonus(_owner, reward, _duration) : uint128(reward);
    }

    function calculateBonus(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) private view returns (uint128) {
        uint256 avgBonus = getCurrentAvgBonus(_owner, _duration);
        return uint128(_amount + (_amount * avgBonus) / BONUS_DECIMALS / 100);
    }

    // tokenReward rewards

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, rstStakingPool.generalRewardVars().periodFinish);
    }

    function tokenRewardPerToken() public view returns (uint256) {
        IRstStakingPool.GeneralRewardVars memory _generalRewardVars = rstStakingPool.generalRewardVars();

        if (rstStakingPool.totalSupply() == 0) {
            return _generalRewardVars.tokenRewardPerTokenStored;
        }

        return
            _generalRewardVars.tokenRewardPerTokenStored +
            (uint256(
                lastTimeRewardApplicable() - _generalRewardVars.lastUpdateTime
            ) *
                _generalRewardVars.tokenRewardRate *
                TOKEN_REWARD_DECIMALS) /
            rstStakingPool.totalSupply();
    }

    function tokenRewardEarned(address account) public view returns (uint256) {
        IRstStakingPool.AccountRewardVars memory _accountRewardVars = rstStakingPool.accountRewardVars(account);

        uint256 calculatedEarned = (uint256(rstStakingPool.staked(account)) *
            (tokenRewardPerToken() -
                _accountRewardVars.tokenRewardPerTokenPaid)) /
            TOKEN_REWARD_DECIMALS +
            _accountRewardVars.tokenRewards;
        uint256 poolBalance = address(rstStakingPool.rewardToken()) != address(0) ? rstStakingPool.rewardToken().balanceOf(address(rstStakingPool)) : 0;

        // some rare case the reward can be slightly bigger than real number, we need to check against how much we have left in pool
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    function addTokenRewardPool(uint256 _amount, uint256 _duration)
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRstStakingPool.GeneralRewardVars memory _generalRewardVars = rstStakingPool.generalRewardVars();

        if (_generalRewardVars.periodFinish > block.timestamp) {
            uint256 timeRemaining = _generalRewardVars.periodFinish -
                block.timestamp;
            _amount += timeRemaining * _generalRewardVars.tokenRewardRate;
        }

        rstStakingPool.rewardToken().safeTransferFrom(_msgSender(), address(rstStakingPool), _amount);
        _generalRewardVars.tokenRewardRate = uint128(_amount / _duration);
        _generalRewardVars.periodFinish = uint32(block.timestamp + _duration);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        rstStakingPool.setGeneralRewardVars(_generalRewardVars);
        emit RewardPoolAdded(_amount, _duration, block.timestamp);
    }

    function abortTokenRewardPool()
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRstStakingPool.GeneralRewardVars memory _generalRewardVars = rstStakingPool.generalRewardVars();

        require(
            _generalRewardVars.periodFinish > block.timestamp,
            "pool not active"
        );

        uint256 timeRemaining = _generalRewardVars.periodFinish -
            block.timestamp;
        uint256 remainingAmount = timeRemaining *
            _generalRewardVars.tokenRewardRate;
        rstStakingPool.withdrawRewardToken(_msgSender(), remainingAmount);

        _generalRewardVars.tokenRewardRate = 0;
        _generalRewardVars.periodFinish = uint32(block.timestamp);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        rstStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function withdrawReward()
        external
    {
        balanceUpdate(_msgSender());
        uint256 reward = tokenRewardEarned(_msgSender());
        require(reward > 1, "no reward to withdraw");
        if (reward > 1) {
            IRstStakingPool.AccountRewardVars memory _accountRewardVars = 
                rstStakingPool.accountRewardVars(_msgSender());
            _accountRewardVars.tokenRewards = 0;
            rstStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);
            rstStakingPool.withdrawRewardToken(_msgSender(), reward);
        }

        emit RewardWithdrawn(_msgSender(), reward, block.timestamp);
    }

}
