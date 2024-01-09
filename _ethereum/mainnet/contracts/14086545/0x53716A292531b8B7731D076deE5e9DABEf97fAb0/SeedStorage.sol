// SPDX-License-Identifier: MIT

/// @title RaidParty Seed Storage

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";

contract SeedStorage is AccessControlEnumerable {
    bytes32 public constant WRITE_ROLE = keccak256("WRITE_ROLE");

    mapping(bytes32 => uint256) private _randomness;

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(WRITE_ROLE, admin);
    }

    function getRandomness(bytes32 key) external view returns (uint256) {
        return _randomness[key];
    }

    function setRandomness(bytes32 key, uint256 value)
        external
        onlyRole(WRITE_ROLE)
    {
        require(
            _randomness[key] == 0,
            "SeedStorage::setRandomness: value already set at id"
        );
        _randomness[key] = value;
    }
}
