// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

bytes32 constant COLLECTION_ADMIN_ROLE = keccak256("COLLECTION_ADMIN_ROLE");
bytes32 constant QUESTING_CONTRACT_ROLE = keccak256("QUESTING_CONTRACT_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
bytes32 constant QUEST_MANAGER_ROLE = keccak256("QUEST_MANAGER_ROLE");

bytes32 constant REDEMPTION_CONTRACT_ROLE = keccak256("REDEMPTION_CONTRACT_ROLE");

bytes32 constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

bytes32 constant ITEM_MANAGEMENT_ROLE = keccak256("ITEM_MANAGEMENT_ROLE");

bytes32 constant TOKEN_TRAITS_WRITER_ROLE = keccak256("TOKEN_TRAITS_WRITER_ROLE");

bytes32 constant IMMORTALS_CHILDCHAIN_MINTER_ROLE = keccak256("IMMORTALS_CHILDCHAIN_MINTER_ROLE");

// trait ids
uint256 constant TRAIT_ID_NAME = uint256(keccak256("trait_name"));
uint256 constant TRAIT_ID_DESCRIPTION = uint256(keccak256("trait_description"));
uint256 constant TRAIT_ID_IMAGE = uint256(keccak256("trait_image"));
uint256 constant TRAIT_ID_EXTERNAL_URL = uint256(keccak256("trait_external_url"));
uint256 constant TRAIT_ID_LOCKED = uint256(keccak256("trait_locked"));
uint256 constant TRAIT_ID_SEASON = uint256(keccak256("trait_season"));
uint256 constant TRAIT_ID_RACE = uint256(keccak256("trait_race"));
