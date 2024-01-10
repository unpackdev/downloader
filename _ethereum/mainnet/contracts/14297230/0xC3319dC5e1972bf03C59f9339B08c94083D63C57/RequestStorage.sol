// SPDX-License-Identifier: MIT

/// @title RaidParty Request Storage

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Randomness.sol";

contract RequestStorage is AccessControlEnumerable {
    bytes32 public constant WRITE_ROLE = keccak256("WRITE_ROLE");

    mapping(address => mapping(uint256 => Randomness.SeedData))
        private _seedData;
    mapping(uint256 => bytes32) private _batchToReq;

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(WRITE_ROLE, admin);
    }

    function getRequest(address origin, uint256 identifier)
        external
        view
        returns (Randomness.SeedData memory)
    {
        return _seedData[origin][identifier];
    }

    function getRequestIdFromBatch(uint256 batch)
        external
        view
        returns (bytes32)
    {
        return _batchToReq[batch];
    }

    function setRequest(
        address origin,
        uint256 identifier,
        Randomness.SeedData memory data
    ) external onlyRole(WRITE_ROLE) {
        require(
            _seedData[origin][identifier].batch == 0 &&
                _seedData[origin][identifier].randomnessId == 0,
            "RequestStorage::setRequest: request already set"
        );
        _seedData[origin][identifier] = data;
    }

    function updateRequest(
        address origin,
        uint256 identifier,
        bytes32 randomnessId
    ) external onlyRole(WRITE_ROLE) {
        _seedData[origin][identifier].batch = 0;
        _seedData[origin][identifier].randomnessId = randomnessId;
    }

    function setBatchRequestId(uint256 batch, bytes32 requestId)
        external
        onlyRole(WRITE_ROLE)
    {
        require(
            _batchToReq[batch] == 0,
            "RequestStorage::updateBatchRequestId: id already set"
        );
        _batchToReq[batch] = requestId;
    }
}
