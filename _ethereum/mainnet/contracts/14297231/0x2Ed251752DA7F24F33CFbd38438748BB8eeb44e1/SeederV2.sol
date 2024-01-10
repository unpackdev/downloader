// SPDX-License-Identifier: MIT

/// @title RaidParty Randomness and Seeder V2

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AccessControlEnumerable.sol";
import "./SeedStorage.sol";
import "./RequestStorage.sol";
import "./ISeeder.sol";
import "./Randomness.sol";

contract SeederV2 is VRFConsumerBaseV2, AccessControlEnumerable, ISeeder {
    VRFCoordinatorV2Interface private immutable _coordinator;
    LinkTokenInterface private immutable _linkToken;
    bytes32 private immutable _keyHash;
    ISeeder private immutable _seederV1;
    SeedStorage private immutable _seedStorage;
    RequestStorage private immutable _requestStorage;

    bytes32 public constant INTERNAL_CALLER_ROLE =
        keccak256("INTERNAL_CALLER_ROLE");

    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private _fee;
    uint256 private _lastBatchTimestamp;
    uint256 private _batchCadence;
    uint256 private _batch;
    uint64 private _subscriptionId;

    constructor(
        uint64 subscriptionId,
        address link,
        address coordinator,
        bytes32 keyHash,
        uint256 batch,
        address seederv1,
        address seedStorage,
        address requestStorage,
        address admin,
        uint256 batchCadence
    ) VRFConsumerBaseV2(coordinator) {
        require(batch > 0, "SeederV2: Invalid initial batch");
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(INTERNAL_CALLER_ROLE, admin);

        _coordinator = VRFCoordinatorV2Interface(coordinator);
        _linkToken = LinkTokenInterface(link);
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
        _batch = batch;
        _batchCadence = batchCadence;
        _seederV1 = ISeeder(seederv1);
        _seedStorage = SeedStorage(seedStorage);
        _requestStorage = RequestStorage(requestStorage);
        _fee = 2500000000000000;
    }

    /** PUBLIC */

    // Returns a seed or 0 if not yet seeded
    function getSeed(address origin, uint256 identifier)
        external
        view
        override
        returns (uint256)
    {
        if (_isPreMigration(origin, identifier)) {
            return _seederV1.getSeed(origin, identifier);
        }

        Randomness.SeedData memory data = _getData(origin, identifier);
        uint256 randomness;

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(
                _requestStorage.getRequestIdFromBatch(data.batch)
            );
        }

        if (
            (data.randomnessId == 0 &&
                _requestStorage.getRequestIdFromBatch(data.batch) == 0) ||
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
        if (_isPreMigration(origin, identifier)) {
            return _seederV1.getSeedSafe(origin, identifier);
        }

        Randomness.SeedData memory data = _getData(origin, identifier);
        uint256 randomness;

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(
                _requestStorage.getRequestIdFromBatch(data.batch)
            );
        }

        require(
            (data.randomnessId != 0 ||
                _requestStorage.getRequestIdFromBatch(data.batch) != 0) &&
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
        return _requestStorage.getRequestIdFromBatch(batch);
    }

    function setFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _fee = fee;
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, "SeederV2::withdraw: Failed to send Ether");
    }

    function isSeeded(address origin, uint256 identifier)
        public
        view
        override
        returns (bool)
    {
        Randomness.SeedData memory data;
        uint256 randomness;

        if (_isPreMigration(origin, identifier)) {
            return _seederV1.isSeeded(origin, identifier);
        } else {
            data = _getData(origin, identifier);
        }

        if (data.batch == 0) {
            randomness = _seedStorage.getRandomness(data.randomnessId);
        } else {
            randomness = _seedStorage.getRandomness(
                _requestStorage.getRequestIdFromBatch(data.batch)
            );
        }

        return ((data.randomnessId != 0 ||
            _requestStorage.getRequestIdFromBatch(data.batch) != 0) &&
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
            Randomness.SeedData memory data;
            uint256 idx = startIdx;
            uint256 identifierIdx = 0;

            while (isSeeded(origin, idx)) {
                data = _getData(origin, idx);

                if (
                    data.randomnessId == randomnessId ||
                    _requestStorage.getRequestIdFromBatch(data.batch) ==
                    randomnessId
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
            Randomness.SeedData memory data;
            uint256 idx = startIdx;
            uint256 count = 0;

            while (isSeeded(origin, idx)) {
                data = _getData(origin, idx);

                if (
                    data.randomnessId == randomnessId ||
                    _requestStorage.getRequestIdFromBatch(data.batch) ==
                    randomnessId
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
        Randomness.SeedData memory data = _getData(msg.sender, identifier);
        require(
            data.randomnessId == 0 && data.batch == 0,
            "Seeder::generateSeed: Seed already requested"
        );
        require(
            identifier != 0,
            "Seeder::generateSeed: Identifier cannot be 0"
        );

        _requestStorage.setRequest(
            msg.sender,
            identifier,
            Randomness.SeedData(_batch, 0)
        );

        emit Requested(msg.sender, identifier);
    }

    // executeRequestMulti batch executes requests from the queue
    function executeRequestMulti() external {
        require(
            _lastBatchTimestamp + _batchCadence <= block.timestamp,
            "Seeder::executeRequestMulti: Batch cadence not passed"
        );

        _lastBatchTimestamp = block.timestamp;

        uint256 linkReqID = _coordinator.requestRandomWords(
            _keyHash,
            _subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        _requestStorage.setBatchRequestId(_batch, bytes32(linkReqID));
        unchecked {
            _batch += 1;
        }
    }

    // Executes a single request
    function executeRequest(address origin, uint256 identifier)
        external
        payable
    {
        require(
            !_isPreMigration(origin, identifier),
            "Seeder::executeRequest: Pre-migration requests may not be manually executed"
        );

        Randomness.SeedData memory data = _getData(origin, identifier);

        require(
            _lastBatchTimestamp + _batchCadence > block.timestamp,
            "Seeder::executeRequest: Cannot seed individually during batch seeding"
        );
        require(
            data.randomnessId == 0 &&
                _requestStorage.getRequestIdFromBatch(data.batch) == 0,
            "Seeder::executeRequest: Seed already generated"
        );
        require(
            data.batch != 0,
            "Seeder::executeRequest: Seed not yet requested"
        );

        require(
            msg.value == _fee,
            "Seeder::executeRequest: Transaction value does not match expected fee"
        );

        uint256 linkReqID = _coordinator.requestRandomWords(
            _keyHash,
            _subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        _requestStorage.updateRequest(origin, identifier, bytes32(linkReqID));
    }

    function getSubscriptionId() external view returns (uint64) {
        return _subscriptionId;
    }

    function setBatchCadence(uint256 batchCadence)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _batchCadence = batchCadence;
    }

    function setSubscriptionId(uint64 subscriptionId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _subscriptionId = subscriptionId;
    }

    function getNextAvailableBatch() external view returns (uint256) {
        return _lastBatchTimestamp + _batchCadence;
    }

    function getData(address origin, uint256 identifier)
        external
        view
        returns (Randomness.SeedData memory)
    {
        if (_isPreMigration(origin, identifier)) {
            return _seederV1.getData(origin, identifier);
        }

        return _getData(origin, identifier);
    }

    /** INTERNAL */

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _seedStorage.setRandomness(bytes32(requestId), randomWords[0]);
        emit Seeded(bytes32(requestId), randomWords[0]);
    }

    /** MIGRATION */

    function _getData(address origin, uint256 identifier)
        internal
        view
        returns (Randomness.SeedData memory)
    {
        return _requestStorage.getRequest(origin, identifier);
    }

    // TODO: Fixme for mainnet / testnet
    function _isPreMigration(address origin, uint256 identifier)
        internal
        pure
        returns (bool)
    {
        return ((origin ==
            address(0x966731dFD9b9925DD105FF465687F5aA8f54Ee9f) &&
            identifier <= 5337 &&
            identifier > 0) ||
            (origin == address(0x87E738a3d5E5345d6212D8982205A564289e6324) &&
                identifier <= 9131 &&
                identifier > 0));
    }
}
