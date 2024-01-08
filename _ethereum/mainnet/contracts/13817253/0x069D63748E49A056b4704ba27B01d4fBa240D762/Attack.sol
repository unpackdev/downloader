// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";

import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./IHive.sol";
import "./IAttack.sol";

contract Attack is IAttack, Ownable, Pausable {
    event BearsAttackPrepared(address indexed owner, uint256 indexed nonce, uint256 indexed tokenId, uint256 hiveId);
    event BearsAttackResolved(address indexed owner, uint256 indexed nonce, uint256 tokenId, uint256 successes, uint256 value, uint256 err);
    event BeekeeperAttackPrepared(address indexed owner, uint256 indexed nonce, uint256 indexed tokenId, uint256 hiveId);
    event BeekeeperAttackResolved(address indexed owner, uint256 indexed nonce, uint256 tokenId, uint256 value, uint256 err);

    Settings settings;

    ICryptoBees beesContract;
    IHive hiveContract;

    mapping(uint256 => UnresolvedAttack) public unresolvedAttacks;
    mapping(uint256 => UnresolvedAttack) public unresolvedCollections;

    constructor() {
        settings.bearChance = 40;
        settings.hiveProtectionBear = 4 * 60 * 60; // per success
        settings.beekeeperMultiplier = 4;
        settings.bearCooldownBase = 16 * 60 * 60;
        settings.bearCooldownPerHiveDay = 4 * 60 * 60;
        settings.beekeeperCooldownBase = 16 * 60 * 60;
        settings.beekeeperCooldownPerHiveDay = 4 * 60 * 60;
        settings.attacksToRestart = 7;
    }

    function setContracts(address _BEES, address _HIVE) external onlyOwner {
        beesContract = ICryptoBees(_BEES);
        hiveContract = IHive(_HIVE);
    }

    function setSettings(
        uint8 chance,
        uint24 protectionBear,
        uint8 multiplier,
        uint24 bearCooldown,
        uint24 bearPerHive,
        uint24 keeperCooldown,
        uint24 keeperPerHive,
        uint8 attacksToRestart
    ) external onlyOwner {
        settings.bearChance = chance;
        settings.beekeeperMultiplier = multiplier;
        settings.hiveProtectionBear = protectionBear;
        settings.bearCooldownBase = bearCooldown;
        settings.bearCooldownPerHiveDay = bearPerHive;
        settings.beekeeperCooldownBase = keeperCooldown;
        settings.beekeeperCooldownPerHiveDay = keeperPerHive;
        settings.attacksToRestart = attacksToRestart;
    }

    /** ATTACKS */
    function checkCanAttack(uint16[] calldata hiveIds, uint16[] calldata tokenIds) internal view {
        require(tokenIds.length == hiveIds.length, "ATTACK: THE ARGUMENTS LENGTHS DO NOT MATCH");
        bool duplicates;
        for (uint256 i = 0; i < hiveIds.length; i++) {
            require(beesContract.getTokenData(tokenIds[i])._type == 2, "ATTACK: MUST BE BEAR");
            require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender() || hiveContract.getWaitingRoomOwner(tokenIds[i]) == _msgSender(), "ATTACK: YOU ARE NOT THE OWNER");
            for (uint256 y = 0; y < hiveIds.length; y++) {
                if (i != y && hiveIds[i] == hiveIds[y]) {
                    duplicates = true;
                    break;
                }
            }
        }
        require(!duplicates, "CANNOT ATTACK SAME HIVE WITH TWO BEARS");
    }

    function _resolveAttack(uint256 hiveId) private {
        UnresolvedAttack memory a = unresolvedAttacks[hiveId];
        // there is no unresolved attack for this hive
        if (a.block == 0) return;
        ICryptoBees.Token memory t = beesContract.getTokenData(a.tokenId);
        uint256 owed = 0;
        uint256 successes = 0;
        uint256 err = 0;

        // check if hive is attackable
        if ((hiveContract.getHiveProtectionBears(hiveId) > block.timestamp)) {
            err = 1;
        }

        if (err == 0) {
            uint256 seed = random(a.block);

            (owed, successes) = _attack(t.strength, hiveId, seed);

            // attack was successful let's update some stats
            if (successes >= 1) {
                hiveContract.incSuccessfulAttacks(hiveId);
                hiveContract.setBearAttackData(hiveId, uint32(block.timestamp), uint32(block.timestamp + (settings.hiveProtectionBear * successes)));

                // blow up the hive
                if (hiveContract.getHiveSuccessfulAttacks(hiveId) >= settings.attacksToRestart) {
                    hiveContract.resetHive(hiveId);
                }
                // get the rightful owner (the token might possibly be in the waiting room/staked)
                address _owner;
                if (beesContract.getOwnerOf(a.tokenId) != address(hiveContract)) _owner = beesContract.getOwnerOf(a.tokenId);
                else _owner = hiveContract.getWaitingRoomOwner(a.tokenId);
                beesContract.increaseTokensPot(_owner, owed);
            }
            hiveContract.incTotalAttacks(hiveId);
        }
        emit BearsAttackResolved(_msgSender(), a.nonce, a.tokenId, successes, owed, err);
    }

    function _attack(
        uint256 strength,
        uint256 hiveId,
        uint256 seed
    ) private returns (uint256, uint256) {
        uint256 owed = 0;
        uint256 successes = 0;
        // 5% of the hive
        uint256 beesAffected = hiveContract.getHiveOccupancy(hiveId) / 20;
        if (beesAffected < 5) beesAffected++;

        for (uint256 y = 0; y < beesAffected; y++) {
            if (((seed & 0xFFFF) % 100) < settings.bearChance + (strength * 3)) {
                uint256 beeId = hiveContract.getBeeTokenId(hiveId, y);
                owed += hiveContract.calculateBeeOwed(hiveId, beeId);
                // reset bee's honey
                hiveContract.setBeeSince(hiveId, beeId, uint48(block.timestamp));
                successes += 1;
            }
            if (beesAffected > 1) seed >>= 16;
        }
        return (owed, successes);
    }

    function resolveAttacks(uint16[] calldata hiveIds) public whenNotPaused {
        for (uint256 i = 0; i < hiveIds.length; i++) {
            _resolveAttack(hiveIds[i]);
            delete unresolvedAttacks[hiveIds[i]];
        }
    }

    function manyBearsAttack(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external whenNotPaused {
        checkCanAttack(hiveIds, tokenIds);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _resolveAttack(hiveIds[i]);
            // check if bear can attack
            if (beesContract.getTokenData(tokenIds[i]).cooldownTillTimestamp < block.timestamp && (hiveContract.getHiveProtectionBears(hiveIds[i]) < block.timestamp)) {
                unresolvedAttacks[hiveIds[i]] = UnresolvedAttack({tokenId: tokenIds[i], block: uint64(block.number), nonce: uint48(nonce), howMuch: 0});

                uint48 hiveAge = uint48(block.timestamp) - hiveContract.getHiveAge(hiveIds[i]);
                uint256 cooldown = (((hiveAge / 86400) * settings.bearCooldownPerHiveDay) + settings.bearCooldownBase);
                beesContract.updateTokensLastAttack(tokenIds[i], uint48(block.timestamp), uint48(block.timestamp + cooldown));
                emit BearsAttackPrepared(_msgSender(), nonce, tokenIds[i], hiveIds[i]);
            } else {
                delete unresolvedAttacks[hiveIds[i]];
            }
        }
    }

    /** COLLECTION */
    function checkCanCollect(
        uint16[] calldata hiveIds,
        uint16[] calldata tokenIds,
        uint16[] calldata howMuch
    ) internal view {
        require(tokenIds.length == hiveIds.length && howMuch.length == hiveIds.length, "ATTACK: THE ARGUMENTS LENGTHS DO NOT MATCH");
        bool duplicates;
        for (uint256 i = 0; i < hiveIds.length; i++) {
            require(beesContract.getTokenData(tokenIds[i])._type == 3, "ATTACK: MUST BE BEEKEEPER");
            require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender() || hiveContract.getWaitingRoomOwner(tokenIds[i]) == _msgSender(), "ATTACK: YOU ARE NOT THE OWNER");
            for (uint256 y = 0; y < hiveIds.length; y++) {
                if (i != y && hiveIds[i] == hiveIds[y]) {
                    duplicates = true;
                    break;
                }
            }
        }
        require(!duplicates, "CANNOT ATTACK SAME HIVE WITH TWO BEEKEEPERS");
    }

    function _resolveCollection(uint256 hiveId) private {
        UnresolvedAttack memory a = unresolvedCollections[hiveId];
        // there is no unresolved attack for this hive
        if (a.block == 0) return;
        ICryptoBees.Token memory t = beesContract.getTokenData(a.tokenId);
        uint256 owed = 0;
        uint256 owedPerBee = 0;
        uint256 err = 0;

        // check if hive is attackable
        if (hiveContract.isHiveProtectedFromKeepers(hiveId) == true) {
            err = 1;
        }

        if (err == 0) {
            uint256 seed = random(a.block);

            (owed, owedPerBee) = _collect(t.strength, hiveId, seed, a.howMuch);

            if (owed > 0) {
                hiveContract.setKeeperAttackData(hiveId, uint32(block.timestamp), uint32(owed), uint32(owedPerBee));
                address _owner;
                if (beesContract.getOwnerOf(a.tokenId) != address(hiveContract)) _owner = beesContract.getOwnerOf(a.tokenId);
                else _owner = hiveContract.getWaitingRoomOwner(a.tokenId);
                beesContract.increaseTokensPot(_owner, owed);
            }
        }
        emit BeekeeperAttackResolved(_msgSender(), a.nonce, a.tokenId, owed, err);
    }

    function _collect(
        uint256 strength,
        uint256 hiveId,
        uint256 seed,
        uint256 howMuch
    ) private view returns (uint256, uint256) {
        uint256 owed = 0;
        uint256 owedPerBee = 0;

        if (((seed & 0xFFFF) % 100) < 100 - (howMuch * settings.beekeeperMultiplier) + (strength * 3)) {
            uint256 beesTotal = hiveContract.getHiveOccupancy(hiveId);

            uint256 beeFirst = hiveContract.getBeeTokenId(hiveId, 0);
            uint256 beeLast = hiveContract.getBeeTokenId(hiveId, beesTotal - 1);
            uint256 avg = (hiveContract.calculateBeeOwed(hiveId, beeFirst) + hiveContract.calculateBeeOwed(hiveId, beeLast)) / 2;
            owed = (avg * beesTotal * howMuch) / 100;
            owedPerBee = (avg * howMuch) / 100;
        }
        return (owed, owedPerBee);
    }

    function resolveCollections(uint16[] calldata hiveIds) public whenNotPaused {
        for (uint256 i = 0; i < hiveIds.length; i++) {
            _resolveCollection(hiveIds[i]);
            delete unresolvedCollections[hiveIds[i]];
        }
    }

    function manyBeekeepersCollect(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata howMuch
    ) external whenNotPaused {
        checkCanCollect(hiveIds, tokenIds, howMuch);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _resolveCollection(hiveIds[i]);
            // check if keeper can attack
            if (beesContract.getTokenData(tokenIds[i]).cooldownTillTimestamp < block.timestamp && hiveContract.isHiveProtectedFromKeepers(hiveIds[i]) == false) {
                unresolvedCollections[hiveIds[i]] = UnresolvedAttack({tokenId: tokenIds[i], block: uint64(block.number), nonce: uint48(nonce), howMuch: uint8(howMuch[i])});
                uint48 hiveAge = uint48(block.timestamp) - hiveContract.getHiveAge(hiveIds[i]);
                uint256 cooldown = (((hiveAge / 1 days) * settings.beekeeperCooldownPerHiveDay) + settings.beekeeperCooldownBase);
                beesContract.updateTokensLastAttack(tokenIds[i], uint48(block.timestamp), uint48(block.timestamp + cooldown));
                emit BeekeeperAttackPrepared(_msgSender(), nonce, tokenIds[i], hiveIds[i]);
            } else {
                delete unresolvedCollections[hiveIds[i]];
            }
        }
    }

    /**
     * generates a pseudorandom number
     * @param blockNumber value ensure an attacker doesn't know
     * @return a pseudorandom value
     */
    function random(uint256 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(blockNumber))));
    }
}
