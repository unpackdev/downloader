pragma solidity ^0.7.6;

import "./PriceOracle.sol";

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public controllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingControllerImplementation;
}

contract ControllerStorage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => address[]) public accountAssets;

    /// @notice isListed Whether or not this market is listed
    /**
     * @notice collateralFactorMantissa Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1, and stored as a mantissa.
     */
    /// @notice accountMembership Per-market mapping of "accounts in this asset"
    /// @notice isPied Whether or not this market receives PIE
    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isPied;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    /// @notice index The market's last updated pieBorrowIndex or pieSupplyIndex
    /// @notice block The block number the index was last updated at
    struct PieMarketState {
        uint224 index;
        uint32 block;
    }

    /// @notice A list of all markets
    address[] public allMarkets;

    /// @notice The rate at which the flywheel distributes PIE, per block
    uint public pieRate;

    /// @notice Address of the PIE token
    address public pieAddress;

    // @notice Address of the factory
    address public factory;

    /// @notice The portion of pieRate that each market currently receives
    mapping(address => uint) public pieSpeeds;

    /// @notice The PIE market supply state for each market
    mapping(address => PieMarketState) public pieSupplyState;

    /// @notice The PIE market borrow state for each market
    mapping(address => PieMarketState) public pieBorrowState;

    /// @notice The PIE borrow index for each market for each supplier as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieSupplierIndex;

    /// @notice The PIE borrow index for each market for each borrower as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieBorrowerIndex;

    /// @notice The PIE accrued but not yet transferred to each user
    mapping(address => uint) public pieAccrued;
}