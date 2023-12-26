// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface PoppetErrorsAndEvents {
    error InsufficientFunds();

    error ExceedsMaxSupply();

    error PublicMintUnavailable();

    error SignedMintUnavailable();

    error InvalidSignature();

    error SignatureAlreadyUsed();

    error MismatchedParameters();

    error InsufficientPermissions();

    error ThreadNotActive();

    error CooldownNotComplete();

    error JournalNotEnabled();

    error LockedToken();

    event ThreadStarted(
        uint16 indexed thread_id,
        uint40 indexed end_timestamp,
        uint24 thread_seed
    );

    event PoppetsMinted(
        uint256 indexed start_token_id,
        uint24 indexed seed,
        address indexed minter,
        uint256 quantity
    );

    event PoppetsRevealed(address indexed owner, uint256[] token_ids);

    event PoppetTraitsUpdated(
        uint256 indexed token_id,
        uint256[] removed_official,
        uint256[] added_official,
        uint256[] removed_community,
        uint256[] added_community
    );

    event JournalEntry(uint256 indexed token_id, string ipfs_cid);

    event JournalEntryDisabled(uint256 indexed token_id, string ipfs_cid);

    event WTF(uint256 indexed token_id, uint256 balance, address wallet);

    event WTFBytes(bytes data, bytes data2, uint256 nonce);
}
