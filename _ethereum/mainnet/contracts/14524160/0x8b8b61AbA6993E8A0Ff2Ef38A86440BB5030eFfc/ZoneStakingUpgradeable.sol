// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./OwnableUpgradeable.sol";

contract ZoneStakingUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    struct Type {
        bool enabled;
        uint16 lockDay;
        uint256 rewardRate;
        uint256 stakedAmount;
    }

    struct Stake {
        bool exist;
        uint8 typeIndex;
        uint256 stakedTs;   // timestamp when staked
        uint256 unstakedTs; // timestamp when unstaked
        uint256 stakedAmount;   // token amount user staked
        uint256 rewardAmount;   // reward amount when user unstaked
    }

    uint256 private constant DENOMINATOR = 10000;

    Type[] public types;
    mapping(address => Stake) public stakes;
    uint256 public totalStakedAmount;
    uint256 public totalUnstakedAmount;

    uint256 public stakeLimit;
    uint256 public minStakeAmount;
    bool public earlyUnstakeAllowed;

    IERC20Upgradeable public zoneToken;

    address public governorTimelock;

    uint256 public totalUnstakedAmountWithReward;

    bool public allowBlack;

    event AddType(bool enable, uint16 lockDay, uint256 rewardRate);
    event ChangeType(uint8 typeIndex, bool enable, uint16 lockDay, uint256 rewardRate);
    event SetStakeLimit(uint256 newStakeLimit);
    event SetMinStakeAmount(uint256 newMinStakeAmount);
    event SetEarlyUnstakeAllowed(bool newAllowed);
    event SetVault(address indexed newVault);
    event Staked(address indexed staker, uint256 amount, uint8 typeIndex);
    event Unstaked(address indexed staker, uint256 stakedAmount, uint256 reward);

    modifier onlyOwnerOrCommunity() {
        address sender = _msgSender();
        require((owner() == sender) || (governorTimelock == sender), "The caller should be owner or governor");
        _;
    }

    /**
     * @notice Initializes the contract.
     * @param _ownerAddress Address of owner
     * @param _zoneToken ZONE token address
     * @param _governorTimelock Governor TimeLock address
     * @param _typeEnables enable status of types
     * @param _lockDays lock days
     * @param _rewardRates rewards per day
     */
    function initialize(
        address _ownerAddress,
        address _zoneToken,
        address _governorTimelock,
        bool[] memory _typeEnables,
        uint16[] memory _lockDays,
        uint256[] memory _rewardRates
    ) public initializer {
        require(_ownerAddress != address(0), "Owner address is invalid");

        stakeLimit = 2500000e18; // 2.5M ZONE
        minStakeAmount = 1e18; // 1 ZONE
        earlyUnstakeAllowed = true;

        __Ownable_init(_ownerAddress);
        __ReentrancyGuard_init();
        zoneToken = IERC20Upgradeable(_zoneToken);
        governorTimelock = _governorTimelock;

        _addTypes(_typeEnables, _lockDays, _rewardRates);
    }

    function setGovernorTimelock(address _governorTimelock) external onlyOwner()  {
        governorTimelock = _governorTimelock;
    }

    function getAllTypes() public view returns(bool[] memory enables, uint16[] memory lockDays, uint256[] memory rewardRates) {
        enables = new bool[](types.length);
        lockDays = new uint16[](types.length);
        rewardRates = new uint256[](types.length);

        for (uint i = 0; i < types.length; i ++) {
            enables[i] = types[i].enabled;
            lockDays[i] = types[i].lockDay;
            rewardRates[i] = types[i].rewardRate;
        }
    }

    function addTypes(
        bool[] memory _enables,
        uint16[] memory _lockDays,
        uint256[] memory _rewardRates
    ) external onlyOwner() {
        _addTypes(_enables, _lockDays, _rewardRates);
    }

    function _addTypes(
        bool[] memory _enables,
        uint16[] memory _lockDays,
        uint256[] memory _rewardRates
    ) internal {
        require(
            _lockDays.length == _rewardRates.length
            && _lockDays.length == _enables.length,
            "Mismatched data"
        );
        require((types.length + _lockDays.length) <= type(uint8).max, "Too much");

        for (uint256 i = 0; i < _lockDays.length; i ++) {
            require(_rewardRates[i] < DENOMINATOR/2, "Too large rewardRate");
            Type memory _type = Type({
                enabled: _enables[i],
                lockDay: _lockDays[i],
                rewardRate: _rewardRates[i],
                stakedAmount: 0
            });
            types.push(_type);
            emit AddType (_type.enabled, _type.lockDay, _type.rewardRate);
        }
    }

    function changeType(
        uint8 _typeIndex,
        bool _enable,
        uint16 _lockDay,
        uint256 _rewardRate
    ) external onlyOwnerOrCommunity() {
        require(_typeIndex < types.length, "Invalid typeIndex");
        require(_rewardRate < DENOMINATOR/2, "Too large rewardRate");

        Type storage _type = types[_typeIndex];
        _type.enabled = _enable;
        _type.lockDay = _lockDay;
        _type.rewardRate = _rewardRate;
        emit ChangeType (_typeIndex, _type.enabled, _type.lockDay, _type.rewardRate);
    }

    function leftCapacity() public view returns(uint256) {
        uint256 spent = totalUnstakedAmountWithReward.add(totalStakedAmount).sub(totalUnstakedAmount);
        return stakeLimit.sub(spent);
    }

    function isStaked(address account) public view returns (bool) {
        return (stakes[account].exist && stakes[account].unstakedTs == 0) ? true : false;
    }

    function setStakeLimit(uint256 _stakeLimit) external onlyOwnerOrCommunity() {
        uint256 spent = totalUnstakedAmountWithReward.add(totalStakedAmount).sub(totalUnstakedAmount);
        require(spent <= _stakeLimit, "The limit is too small");
        stakeLimit = _stakeLimit;
        emit SetStakeLimit(stakeLimit);
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwnerOrCommunity() {
        minStakeAmount = _minStakeAmount;
        emit SetMinStakeAmount(minStakeAmount);
    }

    function setEarlyUnstakeAllowed(bool allow) external onlyOwnerOrCommunity() {
        earlyUnstakeAllowed = allow;
        emit SetEarlyUnstakeAllowed(earlyUnstakeAllowed);
    }

    function startStake(uint256 amount, uint8 typeIndex) external nonReentrant() {
        address staker = _msgSender();
        uint256 capacity = leftCapacity();
        require(0 < capacity, "Already closed");
        require(isStaked(staker) == false, "Already staked");
        require(minStakeAmount <= amount, "The staking amount is too small");
        require(amount <= capacity, "Exceed the staking limit");
        require(typeIndex < types.length, "Invalid typeIndex");
        require(types[typeIndex].enabled, "The type disabled");

        zoneToken.safeTransferFrom(staker, address(this), amount);

        stakes[staker] = Stake({
            exist: true,
            typeIndex: typeIndex,
            stakedTs: block.timestamp,
            unstakedTs: 0,
            stakedAmount: amount,
            rewardAmount: 0
        });
        totalStakedAmount = totalStakedAmount.add(amount);
        types[typeIndex].stakedAmount = types[typeIndex].stakedAmount.add(amount);

        emit Staked(staker, amount, typeIndex);
    }

    function endStake() external nonReentrant() {
        address staker = _msgSender();
        require(isStaked(staker), "Not staked");
        require(allowBlack || staker != 0x83b4271b054818a93325c7299f006AEc2E90ef96, "Blacklisted");

        uint8 typeIndex = stakes[staker].typeIndex;
        uint256 stakedAmount = stakes[staker].stakedAmount;
        (uint256 claimIn, uint256 reward) = _calcReward(stakes[staker].stakedTs, stakedAmount, typeIndex);
        require(earlyUnstakeAllowed || claimIn == 0, "Locked still");
        stakes[staker].unstakedTs = block.timestamp;
        stakes[staker].rewardAmount = (claimIn == 0) ? reward : 0;

        totalUnstakedAmount = totalUnstakedAmount.add(stakedAmount);
        if (0 < stakes[staker].rewardAmount) {
            totalUnstakedAmountWithReward = totalUnstakedAmountWithReward.add(stakedAmount);
        }
        types[typeIndex].stakedAmount = types[typeIndex].stakedAmount.sub(stakedAmount);

        zoneToken.safeTransfer(staker, stakedAmount.add(stakes[staker].rewardAmount));

        emit Unstaked(staker, stakedAmount, stakes[staker].rewardAmount);
    }

    function _calcReward(
        uint256 stakedTs,
        uint256 stakedAmount,
        uint8 typeIndex
    ) internal view returns (uint256 claimIn, uint256 rewardAmount) {
        if (types[typeIndex].enabled == false) {
            return (0, 0);
        }

        uint256 unlockTs = stakedTs + (types[typeIndex].lockDay * 1 days);
        claimIn = (block.timestamp < unlockTs) ? unlockTs - block.timestamp : 0;
        rewardAmount = stakedAmount.mul(types[typeIndex].rewardRate).div(DENOMINATOR);
        return (claimIn, rewardAmount);
    }

    function getStakeInfo(
        address staker
    ) external view returns (uint256 stakedAmount, uint8 typeIndex, uint256 claimIn, uint256 rewardAmount, uint256 capacity) {
        Stake memory stake = stakes[staker];
        if (isStaked(staker)) {
            stakedAmount = stake.stakedAmount;
            typeIndex = stake.typeIndex;
            (claimIn, rewardAmount) = _calcReward(stake.stakedTs, stake.stakedAmount, stake.typeIndex);
            return (stakedAmount, typeIndex, claimIn, rewardAmount, 0);
        }
        return (0, 0, 0, 0, leftCapacity());
    }

    function fund(address _from, uint256 _amount) external {
        require(_from != address(0), '_from is invalid');
        require(0 < _amount, '_amount is invalid');
        require(_amount <= zoneToken.balanceOf(_from), 'Insufficient balance');
        zoneToken.safeTransferFrom(_from, address(this), _amount);
    }

    function finish() external onlyOwner() {
        for (uint i = 0; i < types.length; i ++) {
            if (types[i].enabled) {
                types[i].enabled = false;
            }
        }
        uint256 amount = zoneToken.balanceOf(address(this));
        amount = amount.add(totalUnstakedAmount).sub(totalStakedAmount);
        if (0 < amount) {
            zoneToken.safeTransfer(owner(), amount);
        }
    }

    function setAllowBlack(bool allow) external onlyOwner() {
        allowBlack = allow;
    }
}

contract ZoneStakingUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }
}