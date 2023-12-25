// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                  STRUCTS
//////////////////////////////////////////////////////////////////////////*/

/**
 * @notice Struct of dutch auction information
 * - `refunded` Flag indicating if refunds are enabled
 * - `stepLength` Duration (in seconds) of each auction step
 * - `prices` Array of prices for each step of the auction
 */
struct AuctionInfo {
    bool refunded;
    uint248 stepLength;
    uint256[] prices;
}

/**
 * @notice Struct of system config information
 * - `feeReceiver` Address receiving platform fees
 * - `primaryFeeAllocation` Amount of basis points allocated to calculate platform fees on primary sale proceeds
 * - `secondaryFeeAllocation` Amount of basis points allocated to calculate platform fees on royalty payments
 * - `lockTime` Locked time duration added to mint start time for unverified creators
 * - `referrerShare` Share amount distributed to accounts referring tokens
 * - `defaultMetadataURI` Default base URI of token metadata
 * - `externalURI` External URI for displaying tokens
 */
struct ConfigInfo {
    address feeReceiver;
    uint32 primaryFeeAllocation;
    uint32 secondaryFeeAllocation;
    uint32 lockTime;
    uint64 referrerShare;
    string defaultMetadataURI;
    string externalURI;
}

/**
 * @notice Struct of generative art information
 * - `minter` Address of initial token owner
 * - `seed` Hash of randomly generated seed
 * - `fxParams` Random sequence of fixed-length bytes used as token input
 */
struct GenArtInfo {
    address minter;
    bytes32 seed;
    bytes fxParams;
}

/**
 * @notice Struct of initialization information used on project creation
 * - `name` Name of project
 * - `symbol` Symbol of project
 * - `primaryReceiver` Address of splitter contract receiving primary sales
 * - `randomizer` Address of Randomizer contract
 * - `renderer` Address of Renderer contract
 * - `tagIds` Array of tag IDs describing the project
 * - 'onchainData' Onchain data to be stored using SSTORE2 and available to renderers
 */
struct InitInfo {
    string name;
    string symbol;
    address[] primaryReceivers;
    uint32[] allocations;
    address randomizer;
    address renderer;
    uint256[] tagIds;
    bytes onchainData;
}

/**
 * @notice Struct of issuer information
 * - `primaryReceiver` Address of splitter contract receiving primary sales
 * - `projectInfo` Project information
 * - `activeMinters` Array of authorized minter contracts used for enumeration
 * - `minters` Mapping of minter contract to authorization status
 */
struct IssuerInfo {
    address primaryReceiver;
    ProjectInfo projectInfo;
    address[] activeMinters;
    mapping(address => uint8) minters;
}

/**
 * @notice Struct of metadata information
 * - `baseURI` Decoded URI of content identifier
 * - `onchainPointer` Address of bytes-encoded data rendered onchain
 */
struct MetadataInfo {
    bytes baseURI;
    address onchainPointer;
}

/**
 * @notice Struct of mint information
 * - `minter` Address of the minter contract
 * - `reserveInfo` Reserve information
 * - `params` Optional bytes data decoded inside minter
 */
struct MintInfo {
    address minter;
    ReserveInfo reserveInfo;
    bytes params;
}

/**
 * @notice Struct of minter information
 * - `totalMints` Total number of mints executed by the minter
 * - `totalPaid` Total amount paid by the minter
 */
struct MinterInfo {
    uint128 totalMints;
    uint128 totalPaid;
}

/**
 * @notice Struct of project information
 * - `mintEnabled` Flag inidicating if minting is enabled
 * - `burnEnabled` Flag inidicating if burning is enabled
 * - `maxSupply` Maximum supply of tokens
 * - `inputSize` Maximum input size of fxParams bytes data
 * - `earliestStartTime` Earliest possible start time for registering minters
 */
struct ProjectInfo {
    bool mintEnabled;
    bool burnEnabled;
    uint120 maxSupply;
    uint88 inputSize;
    uint32 earliestStartTime;
}

/**
 * @notice Struct of refund information
 * - `lastPrice` Price of last sale before selling out
 * - `minterInfo` Mapping of minter address to struct of minter information
 */
struct RefundInfo {
    uint256 lastPrice;
    mapping(address minter => MinterInfo) minterInfo;
}

/**
 * @notice Struct of reserve information
 * - `startTime` Start timestamp of minter
 * - `endTime` End timestamp of minter
 * - `allocation` Allocation amount for minter
 */
struct ReserveInfo {
    uint64 startTime;
    uint64 endTime;
    uint128 allocation;
}

/**
 * @notice Struct of royalty information
 * - `receiver` Address receiving royalties
 * - `basisPoints` Points used to calculate the royalty payment (0.01%)
 */
struct RoyaltyInfo {
    address receiver;
    uint96 basisPoints;
}

/**
 * @notice Struct of tax information
 * - `startTime` Timestamp of when harberger taxation begins
 * - `foreclosureTime` Timestamp of token foreclosure
 * - `currentPrice` Current listing price of token
 * - `depositAmount` Total amount of taxes deposited
 */
struct TaxInfo {
    uint48 startTime;
    uint48 foreclosureTime;
    uint80 currentPrice;
    uint80 depositAmount;
}
