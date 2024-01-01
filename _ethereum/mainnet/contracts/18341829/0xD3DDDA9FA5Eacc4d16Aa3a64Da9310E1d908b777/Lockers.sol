// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// keccak256("wallet.YugaModule.lockedApe")
bytes32 constant APE_PLAN_LOCKER_SLOT = 0x010881fa8a1edce184936a8e4e08060bba49cb5145c9b396e6e80c0c6b0e1269;

// keccak256("wallet.ERC721Module.lockedERC721")
bytes32 constant CYAN_PLAN_LOCKER_SLOT_ERC721 = 0x25888debd3e1e584ccaebe1162c7763ec457a94078c5d0d9a1d32a926ff9973c;

// keccak256("wallet.ERC1155Module.lockedERC1155")
bytes32 constant CYAN_PLAN_LOCKER_SLOT_ERC1155 = 0xdcc609ac7fc3b6a216ce1445788736c9dbe88a58b25a13af71623e6da931efa0;

// keccak256("wallet.CryptoPunksModule.lockedCryptoPunks")
bytes32 constant CRYPTO_PUNKS_PLAN_LOCKER_SLOT = 0x67ae504a494a1bd5120fdcd8b3565de046d61ac7bb95311090f1976ec179a99a;

struct ApePlanLocker {
    /// @notice Map of the locked tokens.
    ///     Note: Collection Address => Token ID => Lock state
    mapping(address => mapping(uint256 => uint8)) tokens;
}

struct CyanPlanLockerERC721 {
    /// @notice Locked tokens count of the collection.
    ///     Note: Collection Address => Number of locked tokens
    mapping(address => uint256) count;
    /// @notice Map of the locked tokens.
    ///     Note: Collection Address => Token ID => isLocked
    mapping(address => mapping(uint256 => bool)) tokens;
}

struct CyanPlanLockerCryptoPunks {
    /// @notice Locked tokens count of the CryptoPunks.
    ///     Note: Number of locked tokens
    uint256 count;
    /// @notice Map of the locked tokens.
    ///     Note: CryptoPunk index => isLocked
    mapping(uint256 => bool) tokens;
}

/// @notice Checks whether the NFT is locked or not. This method checks both ERC721 lock and ApePlan lock.
/// @param collection Collection address.
/// @param tokenId Token ID.
/// @return isLocked Whether the token is locked or not.
function isLockedERC721(address collection, uint256 tokenId) view returns (bool) {
    return isLockedByCyanPlanERC721(collection, tokenId) || isLockedByApePlan(collection, tokenId);
}

/// @notice Checks whether the ERC721 token is locked or not.
/// @param collection Collection address.
/// @param tokenId Token ID.
/// @return isLocked Whether the token is locked or not.
function isLockedByCyanPlanERC721(address collection, uint256 tokenId) view returns (bool) {
    return getCyanPlanLockerERC721().tokens[collection][tokenId];
}

/// @notice Checks whether the CryptoPunks token is locked or not.
/// @param tokenId Token ID.
/// @return isLocked Whether the token is locked or not.
function isLockedByCryptoPunkPlan(uint256 tokenId) view returns (bool) {
    return getCyanPlanLockerCryptoPunks().tokens[tokenId];
}

/// @notice Checks whether the BAYC, MAYC or BAKC token is locked or not.
/// @param collection Ape collection address.
/// @param tokenId Token ID.
/// @return isLocked Whether the token is ape locked or not.
function isLockedByApePlan(address collection, uint256 tokenId) view returns (bool) {
    return getApePlanLocker().tokens[collection][tokenId] != 0;
}

/// @notice Returns amount of locked ERC1155Token items.
/// @param collection Collection address.
/// @param tokenId Token ID.
/// @return isLocked Whether the token is locked or not.
function getLockedERC1155Amount(address collection, uint256 tokenId) view returns (uint256) {
    return getCyanPlanLockerERC1155()[collection][tokenId];
}

/// @notice Returns ape lock state.
/// @param collection Ape collection address.
/// @param tokenId Token ID.
/// @return Ape locks state.
function getApeLockState(address collection, uint256 tokenId) view returns (uint8) {
    return getApePlanLocker().tokens[collection][tokenId];
}

/// @dev Returns the map of the locked ERC721 tokens.
/// @return result CyanPlanLockerERC721 struct of the locked tokens.
///     Note: Collection Address => Token ID => isLocked
function getCyanPlanLockerERC721() pure returns (CyanPlanLockerERC721 storage result) {
    assembly {
        result.slot := CYAN_PLAN_LOCKER_SLOT_ERC721
    }
}

/// @dev Returns the map of the locked ERC1155 tokens.
/// @return result CyanPlanERC1155Locker struct of the locked tokens.
///     Note: Collection Address => Token ID => locked amount
function getCyanPlanLockerERC1155() pure returns (mapping(address => mapping(uint256 => uint256)) storage result) {
    assembly {
        result.slot := CYAN_PLAN_LOCKER_SLOT_ERC1155
    }
}

/// @dev Returns the map of the locked Crypto Punks.
/// @return result CryptoPunksPlanLocker struct of the locked tokens.
///     Note: CryptoPunk index => isLocked
function getCyanPlanLockerCryptoPunks() pure returns (CyanPlanLockerCryptoPunks storage result) {
    assembly {
        result.slot := CRYPTO_PUNKS_PLAN_LOCKER_SLOT
    }
}

/// @dev Returns the map of the locked tokens.
/// @return result ApePlanLocker struct of the locked tokens.
///     Note: Collection Address => Token ID => Lock state
function getApePlanLocker() pure returns (ApePlanLocker storage result) {
    assembly {
        result.slot := APE_PLAN_LOCKER_SLOT
    }
}
