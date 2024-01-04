// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./IFarm.sol";
import "./IFarmActivator.sol";

contract Farm is Initializable, IFarm, IFarmActivator {
    event Stake(address indexed _staker, uint256 _timestamp, uint256 _amount);
    event Withdraw(address indexed _staker, uint256 _timestamp, uint256 _amount);
    event Harvest(address indexed _staker, uint256 _id, uint256 _timestamp, uint256 _amount);
    event Claim(address indexed _staker, uint256 indexed _harvestId, uint256 _timestamp, uint256 _amount);

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 private constant REWARD_REDUCTION_PERCENT = 20;
    uint256 private constant REWARD_REDUCTION_INTERVAL = 10 days;
    uint256 private constant HARVEST_INTERVAL = 1 days;

    struct Harvests {
        uint256 count;
        uint256 firstUnclaimedId;
        uint256[] timestamps;
        uint256[] claimed;
        uint256[] total;
    }

    address private activator;
    bool private isFarmingStarted;
    uint256 private totalReward;
    uint256 private rewardLeftover;
    uint256 private currentReward;
    uint256 public currentRewardPerSecond;
    IERC20 private rewardToken;
    IERC20 private farmToken;
    uint256 public nextInterval;
    uint256 public lastUpdate;
    uint256 public cumulativeRewardPerToken;
    uint256 private totalBalance;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private unharvestedRewards;
    mapping(address => uint256) private lastCumulativeRewardsPerToken;
    mapping(address => Harvests) private harvests;

    function initialize(address _activator) external initializer {
        __Farm_init(_activator);
    }

    function __Farm_init(address _activator) internal initializer {
        __Farm_init_unchained(_activator);
    }

    function __Farm_init_unchained(address _activator) internal initializer {
        activator = _activator;
    }

    modifier onlyActivator() {
        require(msg.sender == activator, "Only activator allowed.");
        _;
    }

    modifier farmingNotStarted() {
        require(!isFarmingStarted, "Farming was already started.");
        _;
    }

    modifier farmingStarted() {
        require(isFarmingStarted, "Farming not started yet.");
        _;
    }

    modifier rewardTokensDeposited(address _rewardToken) {
        uint256 balance = IERC20(_rewardToken).balanceOf(address(this));
        require(balance > 0, "Reward tokens are not deposited.");
        _;
    }

    modifier stakeAddressNotContract() {
        require(!address(msg.sender).isContract(), "Staking from contracts is not allowed.");
        _;
    }

    modifier stakeAmountValid(uint256 _amount) {
        require(_amount > 0, "Staking amount must be bigger than 0.");
        require(
            _amount <= farmToken.allowance(msg.sender, address(this)),
            "Farm is not allowed to transfer the desired staking amount."
        );
        _;
    }

    modifier withdrawAmountValid(uint256 _amount) {
        require(_amount > 0, "Withdraw amount is zero.");
        require(_amount <= balances[msg.sender], "Withdraw amount too big.");
        _;
    }

    function farmingActive() external view override returns (bool) {
        return isFarmingStarted;
    }

    function totalRewardSupply() external view override returns (uint256) {
        return totalReward;
    }

    function intervalReward() external view override returns (uint256) {
        if (block.timestamp < nextInterval) {
            return currentReward;
        }
        return getReward(getNextRewardLeftover(rewardLeftover, currentReward));
    }

    function rewardIntervalLength() external view override returns (uint256) {
        return REWARD_REDUCTION_INTERVAL;
    }

    function harvestIntervalLength() external view override returns (uint256) {
        return HARVEST_INTERVAL;
    }

    function nextIntervalTimestamp() external view override returns (uint256) {
        return nextInterval.add(block.timestamp >= nextInterval ? REWARD_REDUCTION_INTERVAL : 0);
    }

    function rewardTokenAddress() external view override returns (address) {
        return address(rewardToken);
    }

    function farmTokenAddress() external view override returns (address) {
        return address(farmToken);
    }

    function singleStaked(address _staker) external view override returns (uint256) {
        return balances[_staker];
    }

    function totalStaked() external view override returns (uint256) {
        return totalBalance;
    }

    function startFarming(address _rewardToken, address _farmToken)
        external
        override
        onlyActivator
        farmingNotStarted
        rewardTokensDeposited(_rewardToken)
    {
        rewardToken = IERC20(_rewardToken);
        farmToken = IERC20(_farmToken);
        totalReward = rewardToken.balanceOf(address(this));
        rewardLeftover = totalReward;
        currentReward = getReward(rewardLeftover);
        currentRewardPerSecond = getRewardPerSecond(currentReward);
        isFarmingStarted = true;
        lastUpdate = block.timestamp;
        nextInterval = block.timestamp.add(REWARD_REDUCTION_INTERVAL);
    }

    function stake(uint256 _amount) external override farmingStarted stakeAddressNotContract stakeAmountValid(_amount) {
        update();
        farmToken.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        totalBalance = totalBalance.add(_amount);
        emit Stake(msg.sender, block.timestamp, _amount);
    }

    function withdraw(uint256 _amount) external override farmingStarted withdrawAmountValid(_amount) {
        update();
        farmToken.transfer(msg.sender, _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalBalance = totalBalance.sub(_amount);
        emit Withdraw(msg.sender, block.timestamp, _amount);
    }

    function harvest() external override farmingStarted {
        update();
        uint256 rewardToHarvest = unharvestedRewards[msg.sender];
        if (rewardToHarvest == 0) {
            return;
        }
        unharvestedRewards[msg.sender] = 0;
        harvests[msg.sender].count++;
        harvests[msg.sender].claimed.push(0);
        harvests[msg.sender].timestamps.push(block.timestamp);
        harvests[msg.sender].total.push(rewardToHarvest);
        emit Harvest(msg.sender, harvests[msg.sender].count - 1, block.timestamp, rewardToHarvest);
    }

    function claim() external override farmingStarted {
        uint256 claimableAmount = 0;
        uint256 idOffset = harvests[msg.sender].firstUnclaimedId;
        uint256[] memory parts = claimableHarvests(msg.sender);

        for (uint256 i = 0; i < parts.length; i++) {
            if (parts[i] == 0) {
                break;
            }

            uint256 id = i.add(idOffset);
            harvests[msg.sender].claimed[id] = harvests[msg.sender].claimed[id].add(parts[i]);
            if (harvests[msg.sender].claimed[id] >= harvests[msg.sender].total[id]) {
                harvests[msg.sender].firstUnclaimedId++;
            }

            claimableAmount = claimableAmount.add(parts[i]);
            emit Claim(msg.sender, id, block.timestamp, parts[i]);
        }

        if (claimableAmount > 0) {
            rewardToken.transfer(msg.sender, claimableAmount);
        }
    }

    function harvestable(address _staker) external view override returns (uint256) {
        uint256 checkpointToTimestamp = MathUpgradeable.min(block.timestamp, nextInterval);
        uint256 toCumulativeRewardPerToken =
            getCumulativeRewardPerToken(
                lastUpdate,
                checkpointToTimestamp,
                cumulativeRewardPerToken,
                currentRewardPerSecond
            );
        uint256 unharvestedReward =
            getUnharvestedReward(
                _staker,
                lastCumulativeRewardsPerToken[_staker],
                toCumulativeRewardPerToken,
                unharvestedRewards[_staker]
            );

        if (block.timestamp > checkpointToTimestamp) {
            uint256 fromCumulativeRewardPerToken = toCumulativeRewardPerToken;
            uint256 newRewardPerSecond =
                getRewardPerSecond(getReward(getNextRewardLeftover(rewardLeftover, currentReward)));
            toCumulativeRewardPerToken = getCumulativeRewardPerToken(
                checkpointToTimestamp,
                block.timestamp,
                fromCumulativeRewardPerToken,
                newRewardPerSecond
            );
            unharvestedReward = getUnharvestedReward(
                _staker,
                fromCumulativeRewardPerToken,
                toCumulativeRewardPerToken,
                unharvestedReward
            );
        }
        return unharvestedReward;
    }

    function claimable(address _staker) external view override returns (uint256) {
        uint256[] memory parts = claimableHarvests(_staker);
        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < parts.length; i++) {
            claimableAmount = claimableAmount.add(parts[i]);
        }
        return claimableAmount;
    }

    function harvested(address _staker) external view override returns (uint256) {
        uint256 harvestedAmount = 0;
        for (uint256 i = harvests[_staker].firstUnclaimedId; i < harvests[_staker].count; i++) {
            harvestedAmount = harvestedAmount.add(harvests[_staker].total[i].sub(harvests[_staker].claimed[i]));
        }
        return harvestedAmount;
    }

    function harvestChunk(address _staker, uint56 _id)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint256 claimed,
            uint256 total
        )
    {
        bool harvestExists = harvests[_staker].count > _id;
        timestamp = harvestExists ? harvests[_staker].timestamps[_id] : 0;
        claimed = harvestExists ? harvests[_staker].claimed[_id] : 0;
        total = harvestExists ? harvests[_staker].total[_id] : 0;
    }

    function claimableHarvests(address _staker) private view returns (uint256[] memory) {
        if (harvests[_staker].count == 0 || harvests[_staker].firstUnclaimedId >= harvests[_staker].count) {
            return new uint256[](0);
        }

        uint256 count = harvests[_staker].count.sub(harvests[_staker].firstUnclaimedId);
        uint256[] memory parts = new uint256[](count);

        for (uint256 i = harvests[_staker].firstUnclaimedId; i < harvests[_staker].count; i++) {
            uint256 daysSinceHarvest = block.timestamp.sub(harvests[_staker].timestamps[i]).div(HARVEST_INTERVAL);
            uint256 percentClaimable = daysSinceHarvest >= 10 ? 100 : daysSinceHarvest.mul(10);
            uint256 totalClaimableAmount = harvests[_staker].total[i].mul(percentClaimable).div(100);
            parts[i] = harvests[_staker].claimed[i] < totalClaimableAmount
                ? totalClaimableAmount.sub(harvests[_staker].claimed[i])
                : 0;
        }

        return parts;
    }

    function update() private {
        updateUnharvestedReward();
        updateNextIntervalAndUnharvestedReward();
    }

    function updateUnharvestedReward() private {
        uint256 updateToTimestamp = MathUpgradeable.min(block.timestamp, nextInterval);
        cumulativeRewardPerToken = getCumulativeRewardPerToken(
            lastUpdate,
            updateToTimestamp,
            cumulativeRewardPerToken,
            currentRewardPerSecond
        );
        lastUpdate = updateToTimestamp;
        unharvestedRewards[msg.sender] = getUnharvestedReward(
            msg.sender,
            lastCumulativeRewardsPerToken[msg.sender],
            cumulativeRewardPerToken,
            unharvestedRewards[msg.sender]
        );
        lastCumulativeRewardsPerToken[msg.sender] = cumulativeRewardPerToken;
    }

    function updateNextIntervalAndUnharvestedReward() private {
        if (block.timestamp < nextInterval) {
            return;
        }
        rewardLeftover = getNextRewardLeftover(rewardLeftover, currentReward);
        currentReward = getReward(rewardLeftover);
        currentRewardPerSecond = getRewardPerSecond(currentReward);
        nextInterval = nextInterval.add(REWARD_REDUCTION_INTERVAL);
        updateUnharvestedReward();
    }

    function getCumulativeRewardPerToken(
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint256 _fromCumulativeRewardPerToken,
        uint256 _rewardPerSecond
    ) private view returns (uint256) {
        if (totalBalance == 0) {
            return _fromCumulativeRewardPerToken;
        }
        return
            _fromCumulativeRewardPerToken.add(
                _toTimestamp
                    .sub(_fromTimestamp)
                    .mul(1 ether) // we must multiply it, since number would be decimal otherwise
                    .mul(_rewardPerSecond)
                    .div(totalBalance)
            );
    }

    function getUnharvestedReward(
        address _staker,
        uint256 _fromCumulativeRewardPerToken,
        uint256 _toCumulativeRewardPerToken,
        uint256 _fromUnharvestedReward
    ) private view returns (uint256) {
        return
            balances[_staker].mul(_toCumulativeRewardPerToken.sub(_fromCumulativeRewardPerToken)).div(1 ether).add(
                _fromUnharvestedReward
            );
    }

    function getNextRewardLeftover(uint256 _rewardLeftover, uint256 _reward) private pure returns (uint256) {
        return _rewardLeftover.sub(_reward);
    }

    function getReward(uint256 _rewardLeftover) private pure returns (uint256) {
        return _rewardLeftover.mul(REWARD_REDUCTION_PERCENT).div(100);
    }

    function getRewardPerSecond(uint256 _reward) private pure returns (uint256) {
        return _reward.div(REWARD_REDUCTION_INTERVAL);
    }

    uint256[33] private __gap;
}
