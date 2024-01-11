// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract UnifarmCohortRegistryUpgradeableStorage {
    /// @notice TokenMetaData struct hold the token information.
    struct TokenMetaData {
        // farm id
        uint32 fid;
        // farm token address.
        address farmToken;
        // user min stake for validation.
        uint256 userMinStake;
        // user max stake for validation.
        uint256 userMaxStake;
        // total stake limit for validation.
        uint256 totalStakeLimit;
        // token decimals
        uint8 decimals;
        // can be skip during unstaking
        bool skip;
    }

    /// @notice CohortDetails struct hold the cohort details
    struct CohortDetails {
        // cohort version of a cohort.
        string cohortVersion;
        // start block of a cohort.
        uint256 startBlock;
        // end block of a cohort.
        uint256 endBlock;
        // epoch blocks of a cohort.
        uint256 epochBlocks;
        // indicator for liquidity mining to seprate UI things.
        bool hasLiquidityMining;
        // true if contains any wrapped token in reward.
        bool hasContainsWrappedToken;
        // true if cohort locking feature available.
        bool hasCohortLockinAvaliable;
    }

    /// @notice struct to hold booster configuration for each cohort
    struct BoosterInfo {
        // cohort contract address
        address cohortId;
        // what will be payment token.
        address paymentToken;
        // booster vault address
        address boosterVault;
        // payable amount in terms of PARENT Chain token or ERC20 Token.
        uint256 boosterPackAmount;
    }

    /// @notice mapping contains each cohort details.
    mapping(address => CohortDetails) public cohortDetails;

    /// @notice contains token details by farmId
    mapping(address => mapping(uint32 => TokenMetaData)) public tokenDetails;

    /// @notice contains booster information for specific cohort.
    mapping(address => mapping(uint256 => BoosterInfo)) public boosterInfo;

    /// @notice holds lock status for whole cohort
    mapping(address => bool) public wholeCohortLock;

    /// @notice hold lock status for specific action in specific cohort.
    mapping(address => mapping(bytes4 => bool)) public lockCohort;

    /// @notice hold lock status for specific farm action in a cohort.
    mapping(bytes32 => mapping(bytes4 => bool)) public tokenLockedStatus;

    /// @notice magic value of stake action
    bytes4 public constant STAKE_MAGIC_VALUE = bytes4(keccak256('STAKE'));

    /// @notice magic value of unstake action
    bytes4 public constant UNSTAKE_MAGIC_VALUE = bytes4(keccak256('UNSTAKE'));

    /// @notice multicall address
    address public multiCall;
}
