// SPDX-License-Identifier: MIT

/// @title RaidParty Randomness and Seeder

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./ISeeder.sol";
import "./VRFConsumerBase.sol";
import "./AccessControlEnumerable.sol";
import "./SeedStorage.sol";

contract Seeder is ISeeder, VRFConsumerBase, AccessControlEnumerable {
    bytes32 public constant INTERNAL_CALLER_ROLE =
        keccak256("INTERNAL_CALLER_ROLE");

    mapping(address => mapping(uint256 => SeedData)) private _seedData;
    mapping(uint256 => bytes32) private _batchToReq;
    uint256 private _fee;
    bytes32 private _keyHash;
    uint256 private _lastBatchTimestamp;
    uint256 private _batchCadence = 1 hours;
    uint256 private _batch = 1;
    SeedStorage private _seedStorage;

    constructor(
        address admin,
        address link,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 fee,
        uint256 batchCadence,
        address seedStorage
    ) VRFConsumerBase(vrfCoordinator, link) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(INTERNAL_CALLER_ROLE, admin);
        _keyHash = keyHash;
        _fee = fee;
        _batchCadence = batchCadence;
        _seedStorage = SeedStorage(seedStorage);
    }

    /** PUBLIC */

    // Returns a seed or 0 if not yet seeded
    function getSeed(address origin, uint256 identifier)
        external
        view
        override
        returns (uint256)
    {
        SeedData memory data = _seedData[origin][identifier];
        uint256 randomness;

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(_batchToReq[data.batch]);
        }

        if (
            (data.randomnessId == 0 && _batchToReq[data.batch] == 0) ||
            randomness == 0
        ) {
            return 0;
        } else {
            return
                uint256(keccak256(abi.encode(origin, identifier, randomness)));
        }
    }

    function getSeedSafe(address origin, uint256 identifier)
        external
        view
        override
        returns (uint256)
    {
        SeedData memory data = _seedData[origin][identifier];
        uint256 randomness;

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(_batchToReq[data.batch]);
        }

        require(
            (data.randomnessId != 0 || _batchToReq[data.batch] != 0) &&
                randomness != 0,
            "Seeder::getSeedSafe: got 0 value seed"
        );

        return uint256(keccak256(abi.encode(origin, identifier, randomness)));
    }

    // Returns current batch
    function getBatch() external view returns (uint256) {
        return _batch;
    }

    // Returns req for a given batch
    function getReqByBatch(uint256 batch) external view returns (bytes32) {
        return _batchToReq[batch];
    }

    function isSeeded(address origin, uint256 identifier)
        public
        view
        override
        returns (bool)
    {
        SeedData memory data = _seedData[origin][identifier];
        uint256 randomness;

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(_batchToReq[data.batch]);
        }

        return ((data.randomnessId != 0 || _batchToReq[data.batch] != 0) &&
            randomness != 0);
    }

    // getIdentifiers returns a list of seeded identifiers for a given randomness id, assumes ordered identifier
    function getIdentifiers(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx,
        uint256 count
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory identifiers = new uint256[](count);
            uint256 idx = startIdx;
            uint256 identifierIdx = 0;

            while (isSeeded(origin, idx)) {
                if (
                    _seedData[origin][idx].randomnessId == randomnessId ||
                    _batchToReq[_seedData[origin][idx].batch] == randomnessId
                ) {
                    identifiers[identifierIdx] = idx;
                    identifierIdx += 1;

                    if (identifierIdx == count) {
                        return identifiers;
                    }
                }

                idx += 1;
            }

            revert("Seeder::getIdentifiers: count mismatch");
        }
    }

    function getIdReferenceCount(
        bytes32 randomnessId,
        address origin,
        uint256 startIdx
    ) external view returns (uint256) {
        unchecked {
            uint256 idx = startIdx;
            uint256 count = 0;

            while (isSeeded(origin, idx)) {
                if (
                    _seedData[origin][idx].randomnessId == randomnessId ||
                    _batchToReq[_seedData[origin][idx].batch] == randomnessId
                ) {
                    count += 1;
                }

                idx += 1;
            }

            return count;
        }
    }

    // Requests randomness, limited only to internal callers which must maintain distinct id's
    function requestSeed(uint256 identifier)
        external
        override
        onlyRole(INTERNAL_CALLER_ROLE)
    {
        require(
            _seedData[msg.sender][identifier].randomnessId == 0 &&
                _seedData[msg.sender][identifier].batch == 0,
            "Seeder::generateSeed: Seed already requested"
        );
        require(
            identifier != 0,
            "Seeder::generateSeed: Identifier cannot be 0"
        );

        _seedData[msg.sender][identifier] = SeedData(_batch, 0);

        emit Requested(msg.sender, identifier);
    }

    // executeRequestMulti batch executes requests from the queue
    function executeRequestMulti() external {
        require(
            _lastBatchTimestamp + _batchCadence <= block.timestamp,
            "Seeder::executeRequestMulti: Batch cadence not passed"
        );

        _lastBatchTimestamp = block.timestamp;

        if (LINK.balanceOf(address(this)) < _fee) {
            LINK.transferFrom(address(msg.sender), address(this), _fee);
        }

        bytes32 linkReqID = requestRandomness(_keyHash, _fee);
        _batchToReq[_batch] = linkReqID;
        unchecked {
            _batch += 1;
        }

        if (LINK.balanceOf(address(this)) > 0) {
            LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
        }
    }

    // Executes a single request
    function executeRequest(address origin, uint256 identifier) external {
        SeedData storage data = _seedData[origin][identifier];
        require(
            _lastBatchTimestamp + _batchCadence > block.timestamp,
            "Seeder::executeRequest: Cannot seed individually during batch seeding"
        );
        require(
            data.randomnessId == 0 && _batchToReq[data.batch] == 0,
            "Seeder::generateSeed: Seed already generated"
        );
        require(
            data.batch != 0,
            "Seeder::generateSeed: Seed not yet requested"
        );

        if (LINK.balanceOf(address(this)) < _fee) {
            LINK.transferFrom(address(msg.sender), address(this), _fee);
        }

        bytes32 linkReqID = requestRandomness(_keyHash, _fee);

        data.randomnessId = linkReqID;
        data.batch = 0;

        if (LINK.balanceOf(address(this)) > 0) {
            LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
        }
    }

    function setFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _fee = fee;
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function setBatchCadence(uint256 batchCadence) external {
        _batchCadence = batchCadence;
    }

    function getNextAvailableBatch() external view returns (uint256) {
        return _lastBatchTimestamp + _batchCadence;
    }

    /** INTERNAL */

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        _seedStorage.setRandomness(requestId, randomness);
        emit Seeded(requestId, randomness);
    }
}
