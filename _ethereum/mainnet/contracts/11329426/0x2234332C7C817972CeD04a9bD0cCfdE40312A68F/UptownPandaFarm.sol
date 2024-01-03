// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./IUptownPandaFarm.sol";

contract UptownPandaFarm is IUptownPandaFarm {
    event SupplySnapshotAdded(uint256 idx, uint256 intervalIdx, uint256 timestamp, uint256 totalAmount);
    event SupplySnapshotUpdated(uint256 idx, uint256 intervalIdx, uint256 timestamp, uint256 totalAmount);
    event HarvestChunkAdded(address indexed staker, uint256 idx, uint256 timestamp, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 indexed harvestChunkIdx, uint256 timestamp, uint256 amount);

    using Math for uint256;
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant REWARD_HALVING_INTERVAL = 10 days; // interval for halving the rewards in seconds
    uint256 public constant HARVEST_INTERVAL = 1 days; // how long does it take to increase % of allowed reward withdraw
    uint256 public constant HARVEST_STEP = 10; // how much percent you're allowed to withdraw (after 1 day 10%, after 2 days 20%,...)
    uint256 public immutable HARVEST_CHUNKS_COUNT = uint256(100).div(HARVEST_STEP); // how many parts harvest is split into

    bool public hasFarmingStarted = false; // indicates if farming has begun
    uint256 public initialFarmUpSupply; // inidicates how many $UP tokens were minted for the farm
    address public upTokenAddress; // $UP token address
    address public farmTokenAddress; // address of token to farm with

    IERC20 private upToken; // $UP IERC20 token
    IERC20 private farmToken; // farm IERC20 token

    address private owner;

    struct SupplySnapshot {
        uint256 intervalIdx;
        uint256 timestamp;
        uint256 amount;
    }

    struct HarvestChunk {
        uint256 timestamp;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    SupplySnapshot[] public supplySnapshots;
    mapping(address => uint256) public balances;
    mapping(address => HarvestChunk[]) public harvestChunks;
    mapping(address => uint256) public harvestSnapshotIdxs;

    constructor() public {
        owner = msg.sender;
    }

    modifier originIsOwner() {
        require(owner == tx.origin, "Tx origin is not the owner of the contract.");
        _;
    }

    modifier farmNotStarted() {
        require(!hasFarmingStarted, "Farm has already been started.");
        _;
    }

    modifier farmStarted() {
        require(hasFarmingStarted, "Farm has not been started yet.");
        _;
    }

    modifier farmUpSupplySetCorrectly(address _upToken, uint256 supplyToCheck) {
        require(
            IERC20(_upToken).balanceOf(address(this)) == supplyToCheck,
            "Token supply for this farm is not set correctly!"
        );
        _;
    }

    modifier stakeAddressIsValid() {
        require(!address(msg.sender).isContract(), "Staking from contracts is not allowed.");
        _;
    }

    modifier stakeAmountIsValid(uint256 _amount) {
        require(_amount > 0, "Staking amount must be bigger than 0.");
        _;
    }

    modifier withdrawAmountIsValid(uint256 _amount) {
        require(_amount > 0, "Withdraw amount must be bigger than 0.");
        require(balances[msg.sender] >= _amount, "Requested amount is bigger than your balance.");
        _;
    }

    function startFarming(
        address _upToken,
        address _farmToken,
        uint256 _initialFarmUpSupply
    ) external override originIsOwner farmNotStarted farmUpSupplySetCorrectly(_upToken, _initialFarmUpSupply) {
        addSupplySnapshot(0, block.timestamp, 0);
        upTokenAddress = _upToken;
        farmTokenAddress = _farmToken;
        upToken = IERC20(_upToken);
        farmToken = IERC20(_farmToken);
        initialFarmUpSupply = _initialFarmUpSupply;
        hasFarmingStarted = true;
    }

    function stake(uint256 _amount) external override farmStarted stakeAddressIsValid stakeAmountIsValid(_amount) {
        harvestReward(totalStakedSupply().add(_amount));
        farmToken.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
    }

    function withdraw(uint256 _amount) external override farmStarted withdrawAmountIsValid(_amount) {
        harvestReward(totalStakedSupply().sub(_amount));
        farmToken.transfer(msg.sender, _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
    }

    function harvest() external override farmStarted {
        harvestReward(totalStakedSupply()); // since no funds are added(staking)/subtracted(withdrawing) we just pass in the current supply
    }

    function claim() external override farmStarted {
        claimHarvestedReward();
    }


    function harvestableReward() external view override returns (uint256) {
        if (supplySnapshots.length == 0) {
            return 0;
        }

        uint256 latestSupplySnapshotIdx = supplySnapshots.length.sub(1);
        uint256 total = 0;
        for (uint256 i = harvestSnapshotIdxs[msg.sender]; i < latestSupplySnapshotIdx; i++) {
            total = total.add(calculateChunkRewardFromSupplySnapshot(i));
        }

        SupplySnapshot storage latestSupplySnapshot = supplySnapshots[latestSupplySnapshotIdx];
        uint256 currentIntervalIdx = latestSupplySnapshot.intervalIdx;
        uint256 currentTimestamp = latestSupplySnapshot.timestamp;
        while (true) {
            uint256 nextIntervalIdx = currentIntervalIdx.add(1);
            uint256 nextTimestamp = Math.min(block.timestamp, getIntervalTimestamp(nextIntervalIdx));
            uint256 intervalChunkLength = nextTimestamp.sub(currentTimestamp);
            total = total.add(
                calculateChunkReward(intervalChunkLength, currentIntervalIdx, latestSupplySnapshot.amount)
            );
            if (nextTimestamp == block.timestamp) {
                break;
            }
            currentIntervalIdx = nextIntervalIdx;
            currentTimestamp = nextTimestamp;
        }

        return total;
    }

    function claimableHarvestedReward() external view override returns (uint256) {
        HarvestChunk[] storage stakerHarvestChunks = harvestChunks[msg.sender];
        uint256 total = 0;
        for (uint256 i = 0; i < stakerHarvestChunks.length; i++) {
            total = total.add(getHarvestChunkClaimableAmount(stakerHarvestChunks[i]));
        }
        return total;
    }

    function totalHarvestedReward() external view override returns (uint256) {
        HarvestChunk[] storage stakerHarvestChunks = harvestChunks[msg.sender];
        uint256 total = 0;
        for (uint256 i = 0; i < stakerHarvestChunks.length; i++) {
            total = total.add(stakerHarvestChunks[i].totalAmount.sub(stakerHarvestChunks[i].claimedAmount));
        }
        return total;
    }

    function getHarvestChunkClaimableAmount(HarvestChunk storage _stakerHarvestChunk) private view returns (uint256) {
        uint256 claimPercent = getHarvestChunkClaimPercent(_stakerHarvestChunk.timestamp);
        uint256 claimAmount = _stakerHarvestChunk.totalAmount.mul(claimPercent).div(100);
        return _stakerHarvestChunk.claimedAmount > claimAmount ? 0 : claimAmount.sub(_stakerHarvestChunk.claimedAmount);
    }

    function getHarvestChunkClaimPercent(uint256 _harvestTimestamp) private view returns (uint256) {
        if (_harvestTimestamp >= block.timestamp) {
            return 0;
        }
        uint256 currentChunk = block.timestamp.sub(_harvestTimestamp).div(HARVEST_INTERVAL);
        return currentChunk >= HARVEST_CHUNKS_COUNT ? 100 : currentChunk.mul(HARVEST_STEP);
    }

    function claimHarvestedReward() private {
        HarvestChunk[] storage stakerHarvestChunks = harvestChunks[msg.sender];
        for (uint256 i = 0; i < stakerHarvestChunks.length; i++) {
            uint256 claimableAmount = getHarvestChunkClaimableAmount(stakerHarvestChunks[i]);
            if (claimableAmount == 0) {
                continue;
            }
            upToken.transfer(msg.sender, claimableAmount);
            stakerHarvestChunks[i].claimedAmount = stakerHarvestChunks[i].claimedAmount.add(claimableAmount);
            emit RewardClaimed(msg.sender, i, block.timestamp, claimableAmount);
        }
    }

    function harvestReward(uint256 _newTotalSupply) private {
        updateSupplySnapshots(_newTotalSupply);

        uint256 latestSupplySnapshotIdx = supplySnapshots.length.sub(1);

        if (balances[msg.sender] == 0) {
            harvestSnapshotIdxs[msg.sender] = latestSupplySnapshotIdx;
            return;
        }

        claimHarvestedReward();

        uint256 rewardToHarvest = 0;
        for (uint256 i = harvestSnapshotIdxs[msg.sender]; i < latestSupplySnapshotIdx; i++) {
            rewardToHarvest = rewardToHarvest.add(calculateChunkRewardFromSupplySnapshot(i));
        }
        harvestSnapshotIdxs[msg.sender] = latestSupplySnapshotIdx;
        addHarvestChunk(rewardToHarvest);
    }

    function addHarvestChunk(uint256 _rewardToHarvest) private {
        uint256 idx = harvestChunks[msg.sender].length;
        harvestChunks[msg.sender].push(HarvestChunk(block.timestamp, _rewardToHarvest, 0));
        emit HarvestChunkAdded(msg.sender, idx, block.timestamp, _rewardToHarvest);
    }

    function updateSupplySnapshots(uint256 _newTotalSupply) private {
        uint256 latestSnapshotIdx = supplySnapshots.length.sub(1);
        SupplySnapshot storage latestSnapshot = supplySnapshots[latestSnapshotIdx];
        if (latestSnapshot.timestamp >= block.timestamp) {
            updateSupplySnapshot(latestSnapshotIdx, latestSnapshot, _newTotalSupply);
            return;
        }

        uint256 currentIntervalIdx = latestSnapshot.intervalIdx;
        while (true) {
            uint256 nextIntervalIdx = currentIntervalIdx.add(1);
            uint256 nextIntervalTimestamp = getIntervalTimestamp(nextIntervalIdx);
            uint256 snapshotIntervalIdx = block.timestamp < nextIntervalTimestamp
                ? currentIntervalIdx
                : nextIntervalIdx;
            uint256 snapshotTimestamp = Math.min(block.timestamp, nextIntervalTimestamp);
            uint256 snapshotAmount = snapshotTimestamp == block.timestamp ? _newTotalSupply : latestSnapshot.amount;
            addSupplySnapshot(snapshotIntervalIdx, snapshotTimestamp, snapshotAmount);
            if (snapshotTimestamp == block.timestamp) {
                break;
            }
            currentIntervalIdx = nextIntervalIdx;
        }
    }

    function updateSupplySnapshot(
        uint256 _supplySnapshotIdx,
        SupplySnapshot storage _supplySnapshot,
        uint256 _newTotalSupply
    ) private {
        _supplySnapshot.amount = _newTotalSupply;
        emit SupplySnapshotUpdated(
            _supplySnapshotIdx,
            _supplySnapshot.intervalIdx,
            _supplySnapshot.timestamp,
            _supplySnapshot.amount
        );
    }

    function addSupplySnapshot(
        uint256 _intervalIdx,
        uint256 _timestamp,
        uint256 _amount
    ) private {
        uint256 supplySnapshotIdx = supplySnapshots.length;
        supplySnapshots.push(SupplySnapshot(_intervalIdx, _timestamp, _amount));
        emit SupplySnapshotAdded(supplySnapshotIdx, _intervalIdx, _timestamp, _amount);
    }

    function totalStakedSupply() public view returns (uint256) {
        return supplySnapshots.length > 0 ? supplySnapshots[supplySnapshots.length.sub(1)].amount : 0; // latest entry is current total supply
    }

    function calculateChunkRewardFromSupplySnapshot(uint256 supplySnapshotIdx) private view returns (uint256) {
        uint256 intervalChunkLength = supplySnapshots[supplySnapshotIdx.add(1)].timestamp.sub(
            supplySnapshots[supplySnapshotIdx].timestamp
        );
        return
            calculateChunkReward(
                intervalChunkLength,
                supplySnapshots[supplySnapshotIdx].intervalIdx,
                supplySnapshots[supplySnapshotIdx].amount
            );
    }

    function calculateChunkReward(
        uint256 _intervalChunkLength,
        uint256 _intervalIdx,
        uint256 _supplyAmount
    ) private view returns (uint256) {
        if (_supplyAmount == 0) {
            return 0;
        }
        return
            getIntervalTotalReward(_intervalIdx)
                .mul(_intervalChunkLength)
                .div(REWARD_HALVING_INTERVAL)
                .mul(balances[msg.sender])
                .div(_supplyAmount);
    }

    function nextIntervalTimestamp() external view returns (uint256) {
        if (supplySnapshots.length == 0) {
            return 0;
        }
        uint256 currentIntervalIdx = block.timestamp.sub(supplySnapshots[0].timestamp).div(REWARD_HALVING_INTERVAL);
        return getIntervalTimestamp(currentIntervalIdx.add(1));
    }

    function currentIntervalTotalReward() external view returns (uint256) {
        uint256 currentIntervalIdx = supplySnapshots.length == 0
            ? 0
            : block.timestamp.sub(supplySnapshots[0].timestamp).div(REWARD_HALVING_INTERVAL);
        return getIntervalTotalReward(currentIntervalIdx);
    }

    function getIntervalTotalReward(uint256 _intervalIdx) private view returns (uint256) {
        return initialFarmUpSupply.div(2**_intervalIdx.add(1));
    }

    function getIntervalTimestamp(uint256 _intervalIdx) private view returns (uint256) {
        return
            supplySnapshots.length > 0
                ? supplySnapshots[0].timestamp.add(REWARD_HALVING_INTERVAL.mul(_intervalIdx))
                : 0;
    }
}
