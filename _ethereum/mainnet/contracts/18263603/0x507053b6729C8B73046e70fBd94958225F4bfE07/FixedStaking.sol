//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./AccessControl.sol";

contract FixedStaking is AccessControl {
    struct Stake {
        uint256 amount;
        uint256 stakeAt;
        uint256 stakeType;
        address wallet;
        bool active;
        uint256 canceledAt;
    }

    struct StakeType {
        uint256 duration;
        uint256 interest;
        bool active;
    }

    Stake[] public stakes;
    StakeType[] public stakeTypes;
    IERC20 public token;
    uint256 public poolSize;
    uint256 public minStakeAmount;
    uint256 public maxStakeAmount;
    uint256 public penalty;
    uint256 public stakedToken;
    uint256 public penaltyDuration;

    mapping(address => uint256) public stakedPerWallet;
    event StakeAdded(
        uint256 amount,
        uint256 stakeType,
        address wallet,
        uint256 duration,
        uint256 stakeId
    );
    event StakeClaimed(
        uint256 amount,
        uint256 stakeType,
        address wallet,
        uint256 stakeId
    );
    event StakeUnstaked(
        uint256 amount,
        uint256 stakeType,
        address wallet,
        uint256 stakeId
    );

    event Fund(uint256 amount, address wallet);

    constructor(address _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = IERC20(_token);
        minStakeAmount = 10 ** 19;
        maxStakeAmount = 25 * 10 ** 21;
        penalty = 70;
        penaltyDuration = 5 * 24 * 60 * 60;
    }

    struct ContractView {
        uint256 poolSize;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 penalty;
        uint256 stakedToken;
        uint256 stakesLength;
        uint256 penaltyDuration;
        StakeType[] stakeTypes;
    }

    function contractView() public view returns (ContractView memory) {
        return
            ContractView({
                poolSize: poolSize,
                minStakeAmount: minStakeAmount,
                maxStakeAmount: maxStakeAmount,
                penalty: penalty,
                penaltyDuration: penaltyDuration,
                stakedToken: stakedToken,
                stakesLength: stakes.length,
                stakeTypes: stakeTypes
            });
    }

    function stake(
        uint256 _amount,
        uint256 _stakeType
    ) public returns (uint256) {
        require(
            _amount >= minStakeAmount,
            "Amount should be greater than minStakeAmount"
        );
        require(
            stakedPerWallet[_msgSender()] + _amount <= maxStakeAmount,
            "Amount should be less than maxStakeAmount"
        );
        // stakeType is a number that represents the type of stake
        require(stakeTypes.length > _stakeType, "Invalid stake type");
        StakeType memory _stake = stakeTypes[_stakeType];
        require(_stake.active, "Stake type is not active");

        Stake memory newStake = Stake({
            amount: _amount,
            stakeAt: block.timestamp,
            stakeType: _stakeType,
            wallet: _msgSender(),
            active: true,
            canceledAt: 0
        });
        uint256 reward = computeReward(newStake);
        require(poolSize >= reward, "Not enough rewards in the pool");
        poolSize -= reward;
        stakedToken += _amount;
        stakedPerWallet[_msgSender()] += _amount;
        token.transferFrom(_msgSender(), address(this), _amount);

        stakes.push(newStake);
        emit StakeAdded(
            _amount,
            _stakeType,
            _msgSender(),
            _stake.duration,
            stakes.length - 1
        );
        return stakes.length - 1;
    }

    function claim(uint256 _stakeId) public {
        Stake memory _stake = stakes[_stakeId];
        StakeType memory stakeType = stakeTypes[_stake.stakeType];
        require(_stake.wallet == _msgSender(), "Not your stake");
        require(_stake.active, "Stake is not active");
        if (_stake.canceledAt > 0) {
            require(
                _stake.canceledAt + penaltyDuration < block.timestamp,
                "Stake is canceled. Wait 5 days to claim"
            );
        } else {
            require(
                _stake.stakeAt + stakeType.duration < block.timestamp,
                "Stake is not complete"
            );
        }

        uint256 reward = computeReward(_stake);
        uint256 amount = _stake.amount + reward;

        stakes[_stakeId].active = false;
        stakedToken -= _stake.amount;
        stakedPerWallet[_msgSender()] -= _stake.amount;
        token.transfer(_msgSender(), amount);
        emit StakeClaimed(reward, _stake.stakeType, _msgSender(), _stakeId);
    }

    function computeReward(Stake memory _stake) private view returns (uint256) {
        StakeType memory stakeType = stakeTypes[_stake.stakeType];
        uint256 reward = (_stake.amount * stakeType.interest) / 1000;
        if (_stake.canceledAt > 0) {
            // scale the reward based on amount of time staked
            reward =
                (reward * (_stake.canceledAt - _stake.stakeAt)) /
                stakeType.duration;
            // reduce rewards by penalty
            reward = reward - (reward * penalty) / 100;
        }

        return reward;
    }

    function unstake(uint256 _stakeId) public {
        Stake memory _stake = stakes[_stakeId];
        StakeType memory stakeType = stakeTypes[_stake.stakeType];

        require(_stake.wallet == _msgSender(), "Not your stake");
        require(_stake.active, "Stake is not active");
        require(_stake.canceledAt == 0, "Stake is already canceled");
        require(
            _stake.stakeAt + stakeType.duration > block.timestamp,
            "Stake is completed. Claim it"
        );
        uint256 totalReward = computeReward(_stake);
        _stake.canceledAt = block.timestamp;
        stakes[_stakeId] = _stake;
        uint256 reward = computeReward(_stake);
        poolSize += totalReward - reward;
        emit StakeUnstaked(reward, _stake.stakeType, _msgSender(), _stakeId);
    }

    function restake(uint256 _stakeId, uint256 _newStakeTypeId) public returns (uint256) {
        Stake memory _stake = stakes[_stakeId];
        StakeType memory stakeType = stakeTypes[_stake.stakeType];
        StakeType memory newStakeType = stakeTypes[_newStakeTypeId];
        require(_stake.wallet == _msgSender(), "Not your stake");
        require(_stake.active, "Stake is not active");
        require(stakeTypes.length > _newStakeTypeId, "Invalid stake type");
        require(
            _stake.stakeAt + stakeType.duration < block.timestamp,
            "Stake is not mature"
        );

        uint256 reward = computeReward(_stake);
        uint256 newAmount = _stake.amount + reward;
        stakes[_stakeId].active = false;
        emit StakeClaimed(reward, _stake.stakeType, _msgSender(), _stakeId);
        Stake memory newStake = Stake({
            amount: newAmount,
            stakeAt: block.timestamp,
            stakeType: _newStakeTypeId,
            wallet: _msgSender(),
            active: true,
            canceledAt: 0
        });
        uint256 newReward = computeReward(newStake);
        require(poolSize >= newReward, "Not enough rewards in the pool");
        poolSize -= newReward;
        stakedToken += reward;
        stakedPerWallet[_msgSender()] += reward;
        stakes.push(newStake);
        emit StakeAdded(
            newAmount,
            _newStakeTypeId,
            _msgSender(),
            newStakeType.duration,
            stakes.length - 1
        );
        return stakes.length - 1;
    }

    function addStakeType(
        uint256 _duration,
        uint256 _interest,
        bool _active
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeTypes.push(
            StakeType({
                duration: _duration,
                interest: _interest,
                active: _active
            })
        );
    }

    function setActive(
        uint256 _stakeId,
        bool _active
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeTypes[_stakeId].active = _active;
    }

    function setPenalty(uint256 _penalty) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_penalty > 0, "penalty should be greater than 0");
        require(_penalty <= 100, "penalty should be less than 100");
        penalty = _penalty;
    }

    function setPenaltyDuration(
        uint256 _penaltyDuration
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_penaltyDuration > 0, "penalty should be greater than 0");
        penaltyDuration = _penaltyDuration;
    }

    function setStakeLimits(
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require (
            _minStakeAmount > 0,
            "min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount > _minStakeAmount,
            "max stake amount should be greater than min stake amount");
        minStakeAmount = _minStakeAmount;
        maxStakeAmount = _maxStakeAmount;
    }

    function fund(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transferFrom(_msgSender(), address(this), _amount);
        poolSize += _amount;
        emit Fund(_amount, _msgSender());
    }

    function emergencyWithdrawStake(uint256 _stakeId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Stake memory _stake = stakes[_stakeId];
        stakes[_stakeId].active = false;
        stakedToken -= _stake.amount;
        stakedPerWallet[_stake.wallet] -= _stake.amount;
        uint256 reward = computeReward(_stake);
        poolSize += reward;
        token.transfer(_stake.wallet, _stake.amount);
    }

    function emergencyWithdrawRewards(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount <= poolSize, "Not enough rewards in the pool");
        token.transfer(_msgSender(), _amount);
        poolSize -= _amount;
    }
}
