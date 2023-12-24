// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library KeepersERC721Storage {
    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.keepers.erc721.storage");

    // @dev struct which describes a commit
    // @dev use uint128 for tight variable packing
    struct MintCommit {
        uint128 numNFTs;
        uint128 commitBlock;
    }

    struct Layout {
        // @dev keeps track of available tokens for fisher yates shuffle
        mapping(uint256 => uint256) availableTokens;
        // @dev a mapping of user address to their pending commit
        mapping(address => MintCommit) pendingCommits;
        // Mint parameters
        mapping(address => uint256) mintCountPerAddress;
        // the following variables will be tightly packed
        uint16 numAvailableTokens;
        uint16 maxPerAddress;
        uint32 saleStartTimestamp; // max val in 2106
        uint32 saleCompleteTimestamp;
        uint160 numPendingCommitNFTs;
        address withdrawAddress;
        address vaultAddress;
        uint256 maxMintsForSalesTier; // when kept at 0 it is ignored
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
