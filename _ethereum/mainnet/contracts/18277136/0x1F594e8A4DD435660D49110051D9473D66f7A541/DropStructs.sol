// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @notice A struct for configuration of public mint stage.
 *
 * @param mintPrice                The mint price per token in native token (ETH, MATIC)
 * @param startTime                The start time of the stage, must not be zero.
 * @param endTIme                  The end time of the stage, must not be zero.
 * @param mintLimitPerWallet       Maximum total number of mints a user is
 *                                 allowed.
 */
struct PublicMintStage {
    uint144 mintPrice;
    uint48 startTime;
    uint48 endTime;
    uint16 mintLimitPerWallet;
}

/**
 * @notice A struct for allowlist mint stage.
 *
 * @param id                       The id of the allowlist mint stage
 * @param mintPrice                The mint price per token in native token (ETH, MATIC)
 * @param startTime                The start time of the stage, must not be zero.
 * @param endTIme                  The end time of the stage, must not be zero.
 * @param mintLimitPerWallet       Maximum total number of mints a user is
 *                                 allowed.
 * @param maxSupplyForStage        Maximum allowed supply to be minted in this stage.
 * @param merkleRoot               Merkle root of all allowed addresses.
 */
struct AllowlistMintStage {
    uint80 mintPrice;
    uint48 startTime;
    uint48 endTime;
    uint16 mintLimitPerWallet;
    uint40 maxSupplyForStage;
    bytes32 merkleRoot;
}


/**
 * @notice A struct for token gated mint stage.
 *
 * @param nftContract              The NFT contract address for token gated access
 * @param mintPrice                The mint price per token in native token (ETH, MATIC)
 * @param startTime                The start time of the stage, must not be zero.
 * @param endTime                  The end time of the stage, must not be zero.
 * @param mintLimitPerWallet       Maximum total number of mints a user is
 *                                 allowed.
 * @param maxSupplyForStage        Maximum allowed supply to be minted in this stage.
 */
struct TokenGatedMintStage {
    uint104 mintPrice;
    uint48 startTime;
    uint48 endTime;
    uint16 mintLimitPerWallet;
    uint40 maxSupplyForStage;
}

/**
 * @notice A struct for configuration of allowlist mint stage.
 *
 * @param id                       The id of the allowlist mint stage
 * @param data                     Allowlist mint stage data.
 */
struct AllowlistMintStageConfig {
    uint256 id;
    AllowlistMintStage data;
}

/**
 * @notice A struct for configuration of token gated mint stage.
 *
 * @param nftContract              The NFT contract address for token gated access
 * @param data                     Token gated mint stage data.
 */
struct TokenGatedMintStageConfig {
    address nftContract;
    TokenGatedMintStage data;
}

/**
 * @notice A struct for signed mint params
 *
 * @param mintPrice                The mint price per token in native token (ETH, MATIC)
 * @param startTime                The start time of the stage, must not be zero.
 * @param endTime                  The end time of the stage, must not be zero.
 * @param mintLimitPerWallet       Maximum total number of mints a user is
 *                                 allowed.
 * @param stageIndex               The index of the mint stage.
 * @param maxSupplyForStage        Maximum allowed supply to be minted in this stage.
 */
struct SignedMintParams {
    uint80 mintPrice;
    uint48 startTime;
    uint48 endTime;
    uint16 mintLimitPerWallet;
    uint40 maxSupplyForStage;
    uint256 stageIndex;
}