// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IConfetti.sol";
import "./IParty.sol";
import "./IRaid.sol";
import "./ISeeder.sol";
import "./Seedable.sol";

/// @title RaidParty Raid Contract
/// @author Hasan Gondal <hasan@afraidlabs.com>
/// @notice RAIDOOOOOOOOOOOOOOOOOOOOOOOOOOOOR

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

contract Raid is IRaid, Initializable, AccessControlUpgradeable, Seedable {
    bool public started;
    bool public halted;
    bool public bossesCreated;

    uint32 private roundId;
    uint32 public weightTotal;
    uint64 public lastSnapshotTime;
    uint64 private constant PRECISION = 1e18;

    uint256 public seed;
    uint256 public seedId;

    IParty public party;
    ISeeder public seeder;
    IConfetti public confetti;

    Boss[] public bosses;
    Snapshot[] public snapshots;

    mapping(uint32 => Round) public rounds;
    mapping(address => Raider) public raiders;

    modifier notHalted() {
        require(!halted, "Raid: HALT_ACTIVE");
        _;
    }

    modifier raidActive() {
        require(started, "Raid: NOT_STARTED");
        _;
    }

    modifier partyCaller() {
        require(msg.sender == address(party), "Raid: NOT_PARTY_CALLER");
        _;
    }

    function initialize(
        address admin,
        IParty _party,
        ISeeder _seeder,
        IConfetti _confetti
    ) external initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        party = _party;
        seeder = _seeder;
        confetti = _confetti;
    }

    function setParty(IParty _party) external onlyRole(DEFAULT_ADMIN_ROLE) {
        party = _party;
    }

    function setSeeder(ISeeder _seeder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        seeder = _seeder;
    }

    function setHalted(bool _halted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        halted = _halted;
    }

    function updateSeed() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (started) {
            _syncRounds(uint32(block.number));
        }

        seed = seeder.getSeedSafe(address(this), seedId);
    }

    function requestSeed() external onlyRole(DEFAULT_ADMIN_ROLE) {
        seedId += 1;
        seeder.requestSeed(seedId);
    }

    function createBosses(Boss[] calldata _bosses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete bosses;
        delete weightTotal;

        for (uint256 i; i < _bosses.length; i++) {
            Boss calldata boss = _bosses[i];
            weightTotal += boss.weight;
            bosses.push(boss);
        }

        bossesCreated = true;
    }

    function updateBoss(uint32 id, Boss calldata boss)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bosses.length > id, "Raid::updateBoss: INVALID_BOSS");

        if (started) {
            _syncRounds(uint32(block.number));
        }

        weightTotal -= bosses[id].weight;
        weightTotal += boss.weight;
        bosses[id] = boss;
    }

    function appendBoss(Boss calldata boss)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (started) {
            _syncRounds(uint32(block.number));
        }

        weightTotal += boss.weight;
        bosses.push(boss);
    }

    function manualSync(uint32 maxBlock) external {
        require(
            maxBlock > rounds[roundId].finalBlock,
            "Raid::manualSync: CANNOT_SYNC_PAST"
        );

        _syncRounds(maxBlock);
    }

    function start() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!started, "Raid::start: NOT_STARTED");
        require(bossesCreated, "Raid::start: NO_BOSSES_CREATED");

        seed = seeder.getSeedSafe(address(this), seedId);
        rounds[roundId] = _rollRound(seed, uint32(block.number));

        started = true;
        lastSnapshotTime = uint64(block.timestamp);
    }

    function commitSnapshot() external raidActive {
        require(
            block.timestamp >= lastSnapshotTime + 23 hours,
            "Raid::commitSnapshot: SNAPSHOT_TOO_RECENT"
        );

        _syncRounds(uint32(block.number));

        Snapshot memory snapshot = _createSnapshot();
        snapshots.push(snapshot);

        lastSnapshotTime = uint64(block.timestamp);
    }

    function getRaidData() external view returns (RaidData memory data) {
        uint256 _seed = seed;
        uint32 _roundId = roundId;
        Round memory round = rounds[_roundId];
        while (block.number > round.finalBlock) {
            _roundId += 1;
            _seed = _rollSeed(_seed);
            round = _rollRound(_seed, round.finalBlock + 1);
        }

        data.boss = round.boss;
        data.roundId = _roundId;
        data.health = uint32(round.finalBlock - block.number);
        data.maxHealth = bosses[round.boss].blockHealth;
        data.seed = _seed;
    }

    function getPendingRewards(address user) external view returns (uint256) {
        Raider memory raider = raiders[user];
        (, uint256 rewards) = _fetchRewards(raider);
        return rewards;
    }

    function updateDamage(address user, uint32 _dpb)
        external
        notHalted
        raidActive
        partyCaller
    {
        Raider storage raider = raiders[user];
        if (raider.startedAt == 0) {
            raider.dpb = _dpb;
            raider.startedAt = uint32(block.number);
            raider.startBlock = uint32(block.number);
            raider.startRound = _lazyFetchRoundId(uint32(block.number));
            raider.startSnapshot = uint32(snapshots.length + 1);

            return;
        }

        (uint32 _roundId, uint256 rewards) = _fetchRewards(raider);

        raider.startRound = _roundId;
        raider.pendingRewards = rewards;
        raider.dpb = _dpb;
        raider.startBlock = uint32(block.number);
        raider.startSnapshot = uint32(snapshots.length + 1);
    }

    function claimRewards(address user) external notHalted {
        Raider storage raider = raiders[user];

        (uint32 _roundId, uint256 rewards) = _fetchRewards(raider);

        raider.startRound = _roundId;
        raider.pendingRewards = 0;
        raider.startBlock = uint32(block.number);
        raider.startSnapshot = uint32(snapshots.length + 1);

        if (rewards > 0) {
            confetti.mint(user, rewards);
        }
    }

    /** Internal */

    function _rollSeed(uint256 oldSeed) internal pure returns (uint256 rolled) {
        assembly {
            mstore(0x00, oldSeed)
            rolled := keccak256(0x00, 0x20)
        }
    }

    function _rollRound(uint256 _seed, uint32 startBlock)
        internal
        view
        returns (Round memory round)
    {
        // FIXME: check if we will overflow
        unchecked {
            uint32 roll = uint32(_seed % weightTotal);
            uint256 weight = 0;
            uint32 _bossWeight;

            for (uint16 bossId; bossId < bosses.length; bossId++) {
                _bossWeight = bosses[bossId].weight;

                if (roll <= weight + _bossWeight) {
                    round.boss = bossId;
                    round.roll = roll;
                    round.startBlock = startBlock;
                    round.finalBlock = startBlock + bosses[bossId].blockHealth;

                    return round;
                }

                weight += _bossWeight;
            }
        }
    }

    function _syncRounds(uint32 maxBlock) internal {
        // FIXME: check if we will overflow
        unchecked {
            Round memory round = rounds[roundId];

            while (
                block.number > round.finalBlock && maxBlock > round.finalBlock
            ) {
                roundId += 1;
                seed = _rollSeed(seed);
                round = _rollRound(seed, round.finalBlock + 1);
                rounds[roundId] = round;
            }
        }
    }

    function _createSnapshot()
        internal
        view
        returns (Snapshot memory snapshot)
    {
        uint32 _roundId;

        if (snapshots.length > 0) {
            _roundId = snapshots[snapshots.length - 1].finalRound + 1;
        }

        snapshot.initialRound = _roundId;
        snapshot.initialBlock = rounds[_roundId].startBlock;

        while (_roundId < roundId) {
            Round memory round = rounds[_roundId];
            Boss memory boss = bosses[round.boss];

            snapshot.attackDealt +=
                uint256(boss.blockHealth) *
                uint256(boss.multiplier);

            _roundId += 1;
        }

        snapshot.finalRound = _roundId - 1;
        snapshot.finalBlock = rounds[_roundId - 1].finalBlock;
    }

    function _fetchRewards(Raider memory raider)
        internal
        view
        returns (uint32, uint256)
    {
        if (raider.dpb > 0) {
            if (snapshots.length > raider.startSnapshot) {
                (
                    uint32 _roundId,
                    uint256 rewards
                ) = _fetchNewRewardsWithSnapshot(raider);
                rewards += raider.pendingRewards;
                return (_roundId, rewards);
            } else {
                (uint32 _roundId, uint256 rewards) = _fetchNewRewards(raider);
                rewards += raider.pendingRewards;
                return (_roundId, rewards);
            }
        }

        return (_lazyFetchRoundId(uint32(block.number)), raider.pendingRewards);
    }

    function _fetchNewRewards(Raider memory raider)
        internal
        view
        returns (uint32 _roundId, uint256 rewards)
    {
        // FIXME: check if we will overflow
        unchecked {
            Boss memory boss;
            Round memory round;

            uint256 _seed = seed;

            if (raider.startRound <= roundId) {
                _roundId = raider.startRound;
                for (_roundId; _roundId <= roundId; _roundId++) {
                    round = rounds[_roundId];
                    boss = bosses[round.boss];
                    rewards += _roundReward(raider, round, boss);
                }
                _roundId -= 1;
            } else {
                _roundId = roundId;
                round = rounds[_roundId];
            }

            while (block.number > round.finalBlock) {
                _roundId += 1;
                _seed = _rollSeed(_seed);
                round = _rollRound(_seed, round.finalBlock + 1);
                boss = bosses[round.boss];

                if (_roundId >= raider.startRound) {
                    rewards += _roundReward(raider, round, boss);
                }
            }
        }
    }

    function _fetchNewRewardsWithSnapshot(Raider memory raider)
        internal
        view
        returns (uint32 _roundId, uint256 rewards)
    {
        // FIXME: check if we will overflow
        unchecked {
            Boss memory boss;
            Round memory round;

            _roundId = raider.startRound;
            uint256 _snapshotId = raider.startSnapshot;
            uint32 _lastRound = snapshots[_snapshotId].initialRound;

            for (_roundId; _roundId < _lastRound; _roundId++) {
                round = rounds[_roundId];
                boss = bosses[round.boss];
                rewards += _roundReward(raider, round, boss);
            }

            for (_snapshotId; _snapshotId < snapshots.length; _snapshotId++) {
                rewards += snapshots[_snapshotId].attackDealt * raider.dpb;
                _roundId = snapshots[_snapshotId].finalRound;
                round = rounds[_roundId];
            }

            uint256 _seed = seed;
            while (block.number > round.finalBlock) {
                _roundId += 1;
                _seed = _rollSeed(_seed);
                round = _rollRound(_seed, round.finalBlock + 1);
                boss = bosses[round.boss];
                rewards += _roundReward(raider, round, boss);
            }
        }
    }

    function _lazyFetchRoundId(uint32 maxBlock)
        internal
        view
        returns (uint32 _roundId)
    {
        // FIXME: check if we will overflow
        unchecked {
            _roundId = roundId;
            Round memory round = rounds[_roundId];
            uint256 _seed = seed;
            while (maxBlock > round.finalBlock) {
                _roundId += 1;
                _seed = _rollSeed(_seed);
                round = _rollRound(_seed, round.finalBlock + 1);
            }
        }
    }

    function _roundReward(
        Raider memory raider,
        Round memory round,
        Boss memory boss
    ) internal view returns (uint256 reward) {
        // edge cases -
        // User joins mid round;
        // User joins and leaves mid round;
        // User leaves mid round;
        unchecked {
            uint256 blocksDefeated = boss.blockHealth;

            if (
                round.finalBlock > block.number &&
                raider.startBlock > round.startBlock
            ) {
                blocksDefeated = block.number - raider.startBlock;
            } else if (
                raider.startBlock > round.startBlock &&
                round.finalBlock >= raider.startBlock
            ) {
                blocksDefeated = round.finalBlock - raider.startBlock;
            } else if (
                round.finalBlock > block.number &&
                raider.startBlock >= block.number
            ) {
                blocksDefeated = block.number - round.startBlock;
            }

            reward =
                (1e18 *
                    uint256(blocksDefeated) *
                    uint256(boss.multiplier) *
                    uint256(raider.dpb)) /
                PRECISION;
        }
    }
}
