// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPoolAddressesProviderV1.sol";
import "./ILendingPoolV1.sol";
import "./ILendToAaveMigrator.sol";
import "./IWETH.sol";
import "./IAToken.sol";
import "./FlashLoanReceiverBase.sol";


/**
 * @title Aave V2 Migrator contract
 * @author Zer0dot
 * 
 * @dev This contract migrates your given aTokens and debt positions to V2, using the
 * given rateMode.
 */
contract Migrator is FlashLoanReceiverBase {
    using SafeERC20 for IERC20;
    using SafeERC20 for IAToken;
    using SafeMath for uint256;

    address payable constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant PROVIDER_V2_ADDRESS = address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address constant PROVIDER_V1_ADDRESS = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address constant A_ETH_ADDRESS = address(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04);
    address constant A_LEND_ADDRESS = address(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8);
    address constant AAVE_ADDRESS = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address constant LEND_MIGRATOR_ADDRESS = address(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
    uint256 constant ORIGINATION_FEE = 1e12;
    uint16 constant REF_CODE = 152;

    address payable private caller;         // The user currently migrating. Must never be address(0).
    bool private toDeposit;                 // True if the caller has ETH collateral to migrate, repaying if false.

    // lendingPoolV1 is initialized here, whereas LENDING_POOL is initialized in the constructor.
    ILendingPoolAddressesProvider providerV2 = ILendingPoolAddressesProvider(PROVIDER_V2_ADDRESS);
    ILendingPoolAddressesProviderV1 providerV1 = ILendingPoolAddressesProviderV1(PROVIDER_V1_ADDRESS);
    
    // Initialize the lendingPoolCore address for ETH reception verification.
    // Initialize the lendingPool, lendToAaveMigrator and WETH contracts.
    address coreAddress = providerV1.getLendingPoolCore(); 
    ILendingPoolV1 lendingPoolV1 = ILendingPoolV1(providerV1.getLendingPool()); 
    ILendToAaveMigrator lendMigrator = ILendToAaveMigrator(LEND_MIGRATOR_ADDRESS);
    IWETH weth = IWETH(WETH_ADDRESS);

    /**
     * @dev Constructor initializes LENDING_POOL (the lendingPool V2).
     */ 
    constructor() FlashLoanReceiverBase(providerV2) public {}

    /**
     * @dev This function initiates the migration process for msg.sender.
     *
     * @param aTokens The array of approved aTokens.
     * @param borrowReserves The reserves borrowed on Aave V1.
     * @param rateModes The interest rate modes to borrow with on Aave V2.
     */
    function migrate(
        address[] calldata aTokens,
        address[] calldata borrowReserves,
        uint256[] calldata rateModes
    )
        external
    {
        // Initializes the caller here, and sets it back to address(0) upon completion.
        // This is important because it prevents other functions from being called before this one.
        caller = msg.sender;
        uint256[] memory borrowAmounts = new uint256[](borrowReserves.length);
        uint256[] memory aTokenAmounts = new uint256[](aTokens.length);

        // Loop determines the aToken balances to migrate, taking dust for account.
        for (uint256 i = 0; i < aTokens.length; i++) {
            IERC20 aToken = IERC20(aTokens[i]);
            uint256 balance = aToken.balanceOf(caller);
            require(balance > 0, "Migrator: 0 aToken balance");
            aTokenAmounts[i] = balance;
        }

        // Loop determines the borrow amounts to migrate.
        for (uint256 i = 0; i < borrowReserves.length; i++) {
            ( , uint256 borrowBalance, , , , , , , , ) = lendingPoolV1.getUserReserveData(
                borrowReserves[i],
                caller
            );
            require(borrowBalance > 0, "Migrator: 0 borrow balance");
            borrowAmounts[i] = borrowBalance.add(borrowBalance.mul(ORIGINATION_FEE).div(1e18));
        }

        // For gas efficiency, if the user doesn't have outstanding borrows, skip the flash loan.
        // If the user does have borrows, migrateCollateral must be called from within executeOperation.
        if (borrowReserves.length > 0) {
            bytes memory data = abi.encode(aTokens, aTokenAmounts);
            LENDING_POOL.flashLoan(
                address(this),
                borrowReserves,
                borrowAmounts,
                rateModes,
                caller,
                data,
                REF_CODE
            );
        } else {
            migrateCollateral(aTokens, aTokenAmounts);
        }
        
        // Reset caller to address(0), preventing other external functions from being called.
        caller = address(0);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        require(msg.sender == address(LENDING_POOL), "Migrator: Not the lendingPool");
        require(caller != address(0), "Migrator: Invalid caller");
        //console.log("executeOperation called.");
        (address[] memory aTokens, uint256[] memory aTokenAmounts) = abi.decode(
            params,
            (address[], uint256[])
        );

        // Loop iterates through the flash loaned assets and repays the V1 loans
        // appropriately.
        for (uint256 i = 0; i < assets.length; i++) {

            // If we are receiving wETH, then repayment is done in the receive function.
            if (assets[i] == WETH_ADDRESS) {
                toDeposit = false;
                weth.withdraw(amounts[i]);
            } else {
                IERC20(assets[i]).approve(coreAddress, amounts[i]);
                lendingPoolV1.repay(assets[i], amounts[i], caller);
            }
        }

        // Migrates the aToken collateral.
        migrateCollateral(aTokens, aTokenAmounts);

        // Transfer in the fees to repay the flash loan.
        for (uint i = 0; i < assets.length; i++) {
            IERC20 asset = IERC20(assets[i]);
            asset.safeTransferFrom(caller, address(this), premiums[i]);
            uint amountOwing = amounts[i].add(premiums[i]);
            asset.approve(address(LENDING_POOL), amountOwing);
        }
        return true;
    }

    /**
     * @dev The receive function is a necessity because Aave V1 deals with ETH, whereas Aave
     * V2 deals with wETH. This function can only be called by either the wETH address upon
     * withdrawing ETH to repay an old borrow, or from the lendingPoolCore address when redeeming
     * aETH for ETH to deposit into wETH destined for Aave V2. We use the boolean "toDeposit" to 
     * determine whether the received ETH must..
     *
     *  If toDeposit == true: Deposit the received ETH into wETH.
     *  If toDeposit == false: Repay the caller's ETH V1 debt. 
     */
    receive() external payable {
        require(msg.sender == WETH_ADDRESS ||
            msg.sender == coreAddress,
            "Migrator: Invalid ETH sender"
        );
        require(caller != address(0), "Migrator: Invalid caller");

        if (toDeposit) {    // To deposit.
            weth.deposit{value:msg.value}();
        } else {            // To repay.
            address mockEth = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
            lendingPoolV1.repay{value:msg.value}(mockEth, msg.value, caller);
        }
    }

    /**
     * @dev This function takes care of migrating aTokens from v1 to v2, and is private.
     * It takes into account aLEND to aAAVE migration.
     *
     * @param aTokens The aTokens array passed to migrate.
     * @param aTokenAmounts aTokenAmounts determined in migrate.
     */
    function migrateCollateral(address[] memory aTokens, uint256[] memory aTokenAmounts) private {

        // Loop iterates through all aTokens and migrates appropriately.
        for (uint256 i = 0; i < aTokens.length; i++) {

            // First, the aToken is transferred in from the caller.
            IAToken aToken = IAToken(aTokens[i]);
            aToken.safeTransferFrom(caller, address(this), aTokenAmounts[i]);
            address underlying = aToken.underlyingAssetAddress();

            // If the aToken is aETH, we will receive ETH upon calling redeem.
            // This must be turned to wETH, so we set toDeposit to true, and manually
            // set the underlying address to the wETH address
            if (aTokens[i] == A_ETH_ADDRESS) {
                toDeposit = true;
                underlying = WETH_ADDRESS;
            } 

            aToken.redeem(aTokenAmounts[i]);

            // If the aToken to migrate is aLEND, migrate it to AAVE before depositing AAVE. 
            if (aTokens[i] == A_LEND_ADDRESS) {
                IERC20(underlying).approve(LEND_MIGRATOR_ADDRESS, aTokenAmounts[i]);
                lendMigrator.migrateFromLEND(aTokenAmounts[i]);
                underlying = AAVE_ADDRESS;
                uint256 aaveBalanceAfter = IERC20(underlying).balanceOf(address(this));
                IERC20(underlying).approve(address(LENDING_POOL), aaveBalanceAfter);
                LENDING_POOL.deposit(underlying, aaveBalanceAfter, caller, REF_CODE);
            } else {
                IERC20(underlying).approve(address(LENDING_POOL), aTokenAmounts[i]);
                LENDING_POOL.deposit(underlying, aTokenAmounts[i], caller, REF_CODE);
            }
        }
    }
}