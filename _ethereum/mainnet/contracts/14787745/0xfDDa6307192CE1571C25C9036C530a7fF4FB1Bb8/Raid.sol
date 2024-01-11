// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./IConfetti.sol";
import "./IParty.sol";
import "./IRaid.sol";
import "./ISeeder.sol";

/// @title RaidParty Raid Contract
/// @author Hasan Gondal <hasan@afraidlabs.com>

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

/// @notice Raid is currently halted.
error RaidHalted();

/// @notice Raid has started yet.
error RaidStarted();

/// @notice Raid has not started yet.
error RaidNotStarted();

/// @notice Raid has not been seeded.
error RaidNotSeeded();

/// @notice Bosses have not yet been created.
error MissingBosses();

/// @notice User's local state is invalid, requires them to run `fixInternalState(address user)`.
error InvalidState();

/// @notice The weightTotal should always be above zero when the raid is live.
error InvalidWeightTotal();

/// @notice Invalid boss selected, required `bossId` to be less than `amount`.
/// @param bossId selected bossId.
/// @param amount current amount of bosses.
error InvalidBoss(uint32 bossId, uint32 amount);

/// @notice Invalid caller on current function, requires `expected` caller but current caller is `caller`.
/// @param caller current caller
/// @param expected expected caller
error InvalidCaller(address caller, address expected);

/// @notice Snapshot is being taken too recently, `currentTime` is before `earliestTime`.
/// @param currentTime current timestamp.
/// @param earliestTime next available snapshot time.
error SnapshotTooRecent(uint64 currentTime, uint64 earliestTime);

contract Raid is IRaid, Initializable, AccessControlUpgradeable {
    bool public started;
    bool public halted;
    bool public bossesCreated;

    uint32 private roundId;
    uint32 public weightTotal;
    uint64 public lastSnapshotTime;
    /// @dev DEPRECATED BUT DO NOT REMOVE, THIS WILL BREAK STORAGE;
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

    event HaltUpdated(bool isHalted);

    modifier notHalted() {
        if (halted) revert RaidHalted();
        _;
    }

    modifier raidActive() {
        if (!started) revert RaidNotStarted();
        _;
    }

    modifier partyCaller() {
        address partyAddress = address(party);
        if (msg.sender != partyAddress)
            revert InvalidCaller({caller: msg.sender, expected: partyAddress});
        _;
    }

    constructor() {
        _disableInitializers();
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

        emit HaltUpdated(_halted);
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
        if (!(bosses.length > id)) {
            revert InvalidBoss({bossId: id, amount: uint32(bosses.length)});
        }

        if (started) {
            _syncRounds(uint32(block.number));
        }

        weightTotal -= bosses[id].weight;
        weightTotal += boss.weight;
        bosses[id] = boss;

        if (weightTotal == 0) revert InvalidWeightTotal();
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

    function manualSync() external {
        _syncRounds(uint32(block.number));
    }

    function start() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (started) revert RaidStarted();
        if (!bossesCreated) revert MissingBosses();
        if (weightTotal == 0) revert InvalidWeightTotal();
        if (seedId == 0) revert RaidNotSeeded();

        seed = seeder.getSeedSafe(address(this), seedId);
        rounds[roundId] = _rollRound(seed, uint32(block.number));

        started = true;
        lastSnapshotTime = uint64(block.timestamp);
    }

    function commitSnapshot() external raidActive {
        if (lastSnapshotTime + 23 hours > block.timestamp) {
            revert SnapshotTooRecent({
                currentTime: uint64(block.timestamp),
                earliestTime: lastSnapshotTime + 23 hours
            });
        }

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
        return rewards + raider.pendingRewards;
    }

    function updateDamage(address user, uint32 _dpb)
        external
        notHalted
        raidActive
        partyCaller
    {
        Raider storage raider = raiders[user];
        uint32 blockNumber = uint32(block.number);

        if (raider.startedAt > 0) {
            (uint32 _roundId, uint256 rewards) = _fetchRewards(raider);
            raider.startRound = _roundId;
            raider.pendingRewards += rewards;
        } else {
            raider.startedAt = blockNumber;
            raider.startRound = _lazyFetchRoundId();
        }

        raider.dpb = _dpb;
        raider.startBlock = blockNumber;
        raider.startSnapshot = uint32(snapshots.length + 1);
    }

    function claimRewards(address user) external notHalted {
        Raider storage raider = raiders[user];

        (uint32 _roundId, uint256 rewards) = _fetchRewards(raider);
        rewards += raider.pendingRewards;

        raider.startRound = _roundId;
        raider.pendingRewards = 0;
        raider.startBlock = uint32(block.number);
        raider.startSnapshot = uint32(snapshots.length + 1);

        if (rewards > 0) {
            confetti.mint(user, rewards);
        }
    }

    function fixInternalState(address user) external {
        uint32 _roundId = roundId;
        uint256 _seed = seed;
        Round memory round = rounds[_roundId];
        Raider storage raider = raiders[user];

        unchecked {
            if (raider.startBlock > round.finalBlock) {
                while (raider.startBlock > round.finalBlock) {
                    _roundId += 1;
                    _seed = _rollSeed(_seed);
                    round = _rollRound(_seed, round.finalBlock + 1);
                }
            } else if (raider.startBlock < round.startBlock) {
                while (raider.startBlock < round.startBlock) {
                    _roundId -= 1;
                    round = rounds[_roundId];
                }
            }
        }

        raider.startRound = _roundId;
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
        unchecked {
            Round memory round = rounds[roundId];

            while (maxBlock > round.finalBlock) {
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
        returns (uint32 _roundId, uint256 rewards)
    {
        if (raider.dpb > 0) {
            if (snapshots.length > raider.startSnapshot) {
                (_roundId, rewards) = _fetchNewRewardsWithSnapshot(raider);
                return (_roundId, rewards);
            } else {
                (_roundId, rewards) = _fetchNewRewards(raider);
                return (_roundId, rewards);
            }
        }

        return (_lazyFetchRoundId(), 0);
    }

    function _fetchNewRewards(Raider memory raider)
        internal
        view
        returns (uint32 _roundId, uint256 rewards)
    {
        unchecked {
            Boss memory boss;
            Round memory round;

            uint256 _seed = seed;

            if (raider.startRound <= roundId) {
                _roundId = raider.startRound;
                for (_roundId; _roundId <= roundId; _roundId++) {
                    round = rounds[_roundId];
                    boss = bosses[round.boss];
                    rewards += _rewardCalculation(
                        raider,
                        round,
                        boss.multiplier
                    );
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
                    rewards += _rewardCalculation(
                        raider,
                        round,
                        boss.multiplier
                    );
                }
            }
        }
    }

    function _fetchNewRewardsWithSnapshot(Raider memory raider)
        internal
        view
        returns (uint32 _roundId, uint256 rewards)
    {
        unchecked {
            Boss memory boss;
            Round memory round;

            _roundId = raider.startRound;
            uint256 _snapshotId = raider.startSnapshot;
            uint32 _lastRound = snapshots[_snapshotId].initialRound;

            for (_roundId; _roundId < _lastRound; _roundId++) {
                round = rounds[_roundId];
                boss = bosses[round.boss];
                rewards += _rewardCalculation(raider, round, boss.multiplier);
            }

            for (_snapshotId; _snapshotId < snapshots.length; _snapshotId++) {
                rewards += snapshots[_snapshotId].attackDealt * raider.dpb;
                _roundId = snapshots[_snapshotId].finalRound;
            }

            round = rounds[_roundId];

            while (_roundId < roundId) {
                _roundId += 1;
                round = rounds[_roundId];
                boss = bosses[round.boss];
                rewards += _rewardCalculation(raider, round, boss.multiplier);
            }

            uint256 _seed = seed;
            while (block.number > round.finalBlock) {
                _roundId += 1;
                _seed = _rollSeed(_seed);
                round = _rollRound(_seed, round.finalBlock + 1);
                boss = bosses[round.boss];
                rewards += _rewardCalculation(raider, round, boss.multiplier);
            }
        }
    }

    function _lazyFetchRoundId() internal view returns (uint32 _roundId) {
        unchecked {
            _roundId = roundId;
            Round memory round = rounds[_roundId];
            uint256 _seed = seed;
            while (block.number > round.finalBlock) {
                _roundId += 1;
                _seed = _rollSeed(_seed);
                round = _rollRound(_seed, round.finalBlock + 1);
            }
        }
    }

    function _rewardCalculation(
        Raider memory raider,
        Round memory round,
        uint256 bossMultiplier
    ) internal view returns (uint256 reward) {
        if (raider.startBlock > round.finalBlock) revert InvalidState();

        unchecked {
            uint256 blocksDefeated;

            if (
                round.startBlock >= raider.startBlock &&
                block.number >= round.finalBlock
            ) {
                blocksDefeated = round.finalBlock - round.startBlock;
            } else if (
                raider.startBlock > round.startBlock &&
                block.number >= round.finalBlock
            ) {
                blocksDefeated = round.finalBlock - raider.startBlock;
            } else if (
                round.finalBlock > raider.startBlock &&
                round.startBlock >= raider.startBlock
            ) {
                blocksDefeated = block.number - round.startBlock;
            } else if (
                raider.startBlock > round.startBlock &&
                round.finalBlock > block.number
            ) {
                blocksDefeated = block.number - raider.startBlock;
            }

            // Inline Assembly replaces the following code
            // reward =
            //     (1e18 *
            //         uint256(blocksDefeated) *
            //         uint256(bossMultiplier) *
            //         uint256(raider.dpb)) /
            //     PRECISION;

            assembly {
                reward := div(
                    mul(
                        mul(
                            mul(1000000000000000000, blocksDefeated),
                            bossMultiplier
                        ),
                        and(
                            mload(raider),
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                        )
                    ),
                    1000000000000000000
                )
            }
        }
    }
}
