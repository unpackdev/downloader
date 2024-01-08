// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";


contract LootCharacterChallenges is Ownable, Pausable {
    mapping(uint256 => mapping(uint256 => bool)) public completed;  // ChallengeID => LootCharacterID => Completed
    mapping(address => bool) public updaters;

    modifier onlyUpdater(address updater) {
        require(updaters[updater]);
        _;
    }

    constructor() {}

    function updateChallengeStatus(uint256 challengeId, uint256 lootCharacterId, bool _completed) external whenNotPaused onlyUpdater(msg.sender) {
        completed[challengeId][lootCharacterId] = _completed;
    }

    function setUpdater(address updater, bool canUpdate) external onlyOwner {
        updaters[updater] = canUpdate;
    }
}
