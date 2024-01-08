// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IAttack {
    struct Settings {
        uint8 bearChance;
        uint8 beekeeperMultiplier;
        uint24 hiveProtectionBear;
        uint24 hiveProtectionKeeper;
        uint24 bearCooldownBase;
        uint24 bearCooldownPerHiveDay;
        uint24 beekeeperCooldownBase;
        uint24 beekeeperCooldownPerHiveDay;
        uint8 attacksToRestart;
    }
    struct UnresolvedAttack {
        uint24 tokenId;
        uint48 nonce;
        uint64 block;
        uint32 howMuch;
    }
}
