// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./MToken.sol";
import "./PriceOracle.sol";
import "./LiquidityMathModelInterface.sol";
import "./LiquidationModelInterface.sol";
import "./MProtection.sol";

abstract contract UnitrollerAdminStorage {
    /**
    * @dev Administrator for this contract
    */
    address public admin;

    /**
    * @dev Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @dev Active brains of Unitroller
    */
    address public moartrollerImplementation;

    /**
    * @dev Pending brains of Unitroller
    */
    address public pendingMoartrollerImplementation;
}

contract MoartrollerV1Storage is UnitrollerAdminStorage {

    /**
     * @dev Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @dev Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @dev Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @dev Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @dev Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => MToken[]) public accountAssets;

}

contract MoartrollerV2Storage is MoartrollerV1Storage {
    struct Market {
        // Whether or not this market is listed
        bool isListed;

        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint collateralFactorMantissa;

        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        // Whether or not this market receives MOAR
        bool isMoared;
    }

    /**
     * @dev Official mapping of mTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;


    /**
     * @dev The Pause Guardian can pause certain actions as a safety mechanism.
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
}

contract MoartrollerV3Storage is MoartrollerV2Storage {
    struct MoarMarketState {
        // The market's last updated moarBorrowIndex or moarSupplyIndex
        uint224 index;

        // The block number the index was last updated at
        uint32 block;
    }

    /// @dev A list of all markets
    MToken[] public allMarkets;

    /// @dev The rate at which the flywheel distributes MOAR, per block
    uint public moarRate;

    /// @dev The portion of moarRate that each market currently receives
    mapping(address => uint) public moarSpeeds;

    /// @dev The MOAR market supply state for each market
    mapping(address => MoarMarketState) public moarSupplyState;

    /// @dev The MOAR market borrow state for each market
    mapping(address => MoarMarketState) public moarBorrowState;

    /// @dev The MOAR borrow index for each market for each supplier as of the last time they accrued MOAR
    mapping(address => mapping(address => uint)) public moarSupplierIndex;

    /// @dev The MOAR borrow index for each market for each borrower as of the last time they accrued MOAR
    mapping(address => mapping(address => uint)) public moarBorrowerIndex;

    /// @dev The MOAR accrued but not yet transferred to each user
    mapping(address => uint) public moarAccrued;
}

contract MoartrollerV4Storage is MoartrollerV3Storage {
    // @dev The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @dev Borrow caps enforced by borrowAllowed for each mToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;
}

contract MoartrollerV5Storage is MoartrollerV4Storage {
    /// @dev The portion of MOAR that each contributor receives per block
    mapping(address => uint) public moarContributorSpeeds;

    /// @dev Last block at which a contributor's MOAR rewards have been allocated
    mapping(address => uint) public lastContributorBlock;
}

contract MoartrollerV6Storage is MoartrollerV5Storage {
    /**
     * @dev Moar token address
     */
    address public moarToken;

    /**
     * @dev MProxy address
     */
    address public mProxy;
    
    /**
     * @dev CProtection contract which can be used for collateral optimisation
     */
    MProtection public cprotection;

    /**
     * @dev Mapping for basic token address to mToken
     */
    mapping(address => MToken) public tokenAddressToMToken;

    /**
     * @dev Math model for liquidity calculation
     */
    LiquidityMathModelInterface public liquidityMathModel;


    /**
     * @dev Liquidation model for liquidation related functions
     */
    LiquidationModelInterface public liquidationModel;



    /**
     * @dev List of addresses with privileged access
     */
    mapping(address => uint) public privilegedAddresses;

    /**
     * @dev Determines if reward claim feature is enabled
     */
    bool public rewardClaimEnabled;
}
