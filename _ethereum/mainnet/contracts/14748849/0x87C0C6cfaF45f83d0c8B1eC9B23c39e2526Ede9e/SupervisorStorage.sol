// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./MToken.sol";
import "./PriceOracle.sol";
import "./Buyback.sol";
import "./BDSystem.sol";
import "./EmissionBooster.sol";
import "./Liquidation.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

abstract contract SupervisorV1Storage is AccessControl, ReentrancyGuard {
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);
    uint256 internal constant EXP_SCALE = 1e18;
    uint256 internal constant DOUBLE_SCALE = 1e36;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => MToken[]) public accountAssets;

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint256 utilisationFactorMantissa;
        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        // Multiplier representing the additional collateral which is taken from borrowers
        // as a penalty for being liquidated
        uint256 liquidationFeeMantissa;
    }

    /**
     * @notice Official mapping of mTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The gate keeper can pause certain actions as a safety mechanism
     *  and can set borrowCaps to any number for any market.
     *  Actions which allow accounts to remove their own assets cannot be paused.
     *  Transfer can only be paused globally, not by market.
     *  Lowering the borrow cap could disable borrowing on the given market.
     */
    bool public transferKeeperPaused;
    bool public withdrawMntKeeperPaused;
    mapping(address => bool) public lendKeeperPaused;
    mapping(address => bool) public borrowKeeperPaused;
    mapping(address => bool) public flashLoanKeeperPaused;

    struct MntMarketState {
        // The market's last updated mntBorrowIndex or mntSupplyIndex
        uint224 index;
        // The block number the index was last updated at
        uint32 block;
    }

    struct MntMarketAccountState {
        // The account's last updated mntBorrowIndex or mntSupplyIndex
        uint224 index;
        // The block number in which the index for the account was last updated.
        uint32 block;
    }

    /// @notice A list of all markets
    MToken[] public allMarkets;

    /// @notice The rate at which MNT is distributed to the corresponding supply market (per block)
    mapping(address => uint256) public mntSupplyEmissionRate;

    /// @notice The rate at which MNT is distributed to the corresponding borrow market (per block)
    mapping(address => uint256) public mntBorrowEmissionRate;

    /// @notice The MNT market supply state for each market
    mapping(address => MntMarketState) public mntSupplyState;

    /// @notice The MNT market borrow state for each market
    mapping(address => MntMarketState) public mntBorrowState;

    /// @notice The MNT supply index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(address => mapping(address => MntMarketAccountState)) public mntSupplierState;

    /// @notice The MNT borrow index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(address => mapping(address => MntMarketAccountState)) public mntBorrowerState;

    /// @notice The MNT accrued but not yet transferred to each account
    mapping(address => uint256) public mntAccrued;

    // @notice Borrow caps enforced by beforeBorrow for each mToken address.
    //         Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice Allowances to withdraw MNT on behalf of others
    mapping(address => mapping(address => bool)) public withdrawAllowances;

    /// @notice Buyback contract that implements buy-back logic for all users
    Buyback public buyback;

    /// @notice EmissionBooster contract that provides boost logic for MNT distribution rewards
    EmissionBooster public emissionBooster;

    /// @notice Liquidation contract that can automatically liquidate accounts' insolvent loans
    Liquidation public liquidator;

    /// @notice Contract which manage access to main functionality
    WhitelistInterface public whitelist;

    /// @notice Contract to create agreement and calculate rewards for representative and liquidity provider
    BDSystem public bdSystem;

    uint8 internal initializedVersion;
}
