// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
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
 * given rateMode. USE AT YOUR OWN RISK.
 */
contract Migrator is FlashLoanReceiverBase, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IAToken;
    using SafeMath for uint256;

    address public pauser;
    address constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant MOCK_ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant PROVIDER_V2_ADDRESS = address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address constant PROVIDER_V1_ADDRESS = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address constant A_ETH_ADDRESS = address(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04);
    address constant A_LEND_ADDRESS = address(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8);
    address constant AAVE_ADDRESS = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address constant LEND_MIGRATOR_ADDRESS = address(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
    uint16 constant REF_CODE = 152;     // The referral code to use.         
    address payable caller;             // The user currently migrating. Must never be address(0).
    
    // "lendingPoolV1" is initialized here, whereas "LENDING_POOL", the V2 lendingPool, is initialized in the constructor.
    ILendingPoolAddressesProvider private providerV2 = ILendingPoolAddressesProvider(PROVIDER_V2_ADDRESS);
    ILendingPoolAddressesProviderV1 private providerV1 = ILendingPoolAddressesProviderV1(PROVIDER_V1_ADDRESS);
    
    // Initialize the lendingPoolCore address for ETH reception verification.
    // Initialize the lendingPool, lendToAaveMigrator and WETH contracts.
    address coreAddress = providerV1.getLendingPoolCore();
    ILendingPoolV1 lendingPoolV1 = ILendingPoolV1(providerV1.getLendingPool());
    ILendToAaveMigrator lendMigrator = ILendToAaveMigrator(LEND_MIGRATOR_ADDRESS);
    IWETH weth = IWETH(WETH_ADDRESS);

    /**
     * @dev A simple modifier that prevents functions from executing when the contract
     * is paused due to a flaw or vulnerability. 
     */
    modifier onlyPauser() {
        require(msg.sender == pauser, "Migrator: Must be pauser");
        _;
    }

    /**
     * @dev The constructor initializes "LENDING_POOL", the V2 lendingPool, and the pauser.
     */ 
    constructor() FlashLoanReceiverBase(providerV2) public {
        pauser = msg.sender;
    }

    /**
     * @dev This function initiates the migration process for msg.sender. The caller must delegate
     * the appropriate amount of borrowAllowance for the corresponding debt tokens to borrow.
     * It is recommended to approve a slightly larger amount than the current balance for dust.
     * 
     * @param aTokens The array of approved aTokens. 
     * @param borrowReserves The reserves borrowed on Aave V1. Use the WETH address for ETH borrows.
     * @param rateModes The interest rate modes to borrow with on Aave V2.
     */
    function migrate(
        address[] calldata aTokens,
        address[] calldata borrowReserves,
        uint256[] calldata rateModes
    )
        external
        whenNotPaused
    {
        require(aTokens.length > 0, "Migrator: Empty aToken array");
        // Initializes "caller" here, and sets it back to address(0) upon completion.
        // This is important because it prevents "executeOperation()" from being called before
        // this function.
        caller = msg.sender;
        uint256[] memory borrowAmounts = new uint256[](borrowReserves.length);
        uint256[] memory aTokenAmounts = new uint256[](aTokens.length);

        // Loop determines the aToken balances to migrate.
        for (uint256 i = 0; i < aTokens.length; i++) {
            IERC20 aToken = IERC20(aTokens[i]);
            uint256 balance = aToken.balanceOf(caller);
            require(balance > 0, "Migrator: 0 aToken balance");
            aTokenAmounts[i] = balance;
        }

        // Loop determines the borrow amounts with fees to migrate. Must take into account migrating
        // with active ETH loans by using the MOCK_ETH address from Aave V1.
        for (uint256 i = 0; i < borrowReserves.length; i++) {
            uint256 borrowBalance;
            uint256 originationFee;
            if (borrowReserves[i] == WETH_ADDRESS) {
                ( , borrowBalance, , , , , originationFee, , , ) = lendingPoolV1.getUserReserveData(
                    MOCK_ETH_ADDRESS,
                    caller
                );
            } else {
                ( , borrowBalance, , , , , originationFee, , , ) = lendingPoolV1.getUserReserveData(
                    borrowReserves[i],
                    caller
                );
            }
            require(borrowBalance > 0, "Migrator: 0 borrow balance");
            borrowAmounts[i] = borrowBalance.add(originationFee);
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
        
        // Reset caller to address(0), preventing "executeOperation" from being called from another flash loan
        // without first calling "migrate."
        caller = address(0);
    }

    /**
     * @dev This function must be called only be the LENDING_POOL and takes care of repaying
     * active debt positions, migrating collateral and incurring new V2 debt token debt.
     *
     * @param assets The array of flash loaned assets used to repay debts.
     * @param amounts The array of flash loaned asset amounts used to repay debts.
     * @param premiums The array of premiums incurred as additional debts.
     * @param initiator The address that initiated the flash loan, unused.
     * @param params The byte array containing, in this case, the arrays of aTokens and aTokenAmounts.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        whenNotPaused
        returns (bool)
    {
        require(msg.sender == address(LENDING_POOL), "Migrator: Not the lendingPool");
        require(caller != address(0), "Migrator: Invalid caller");
        
        // Decode the aToken and aToken amounts. This is necessary because we must
        // migrate before the end of the flash loan in order to not be reverted
        // for insufficient collateral.
        (address[] memory aTokens, uint256[] memory aTokenAmounts) = abi.decode(
            params,
            (address[], uint256[])
        );

        // Loop iterates through the flash loaned assets and repays the V1 loans
        // appropriately.
        for (uint256 i = 0; i < assets.length; i++) {

            // Repay the active loans.
            // 
            // We must isolate the ETH loan repayment case because it is not an ERC20 token.
            // Additionally, we cannot execute this logic in the "receive" function due to
            // gas constraints.
            if (assets[i] == WETH_ADDRESS) {
                weth.withdraw(amounts[i]);
                lendingPoolV1.repay{value:amounts[i]}(MOCK_ETH_ADDRESS, amounts[i], caller);
            } else {
                IERC20(assets[i]).approve(coreAddress, amounts[i]);
                lendingPoolV1.repay(assets[i], amounts[i], caller);
            }
        }
        
        // Migrates the aToken collateral.
        migrateCollateral(aTokens, aTokenAmounts);

        // Premiums are accumulated as debt, therefore we don't need to repay the loan.
        return true;
    }

    /**
     * @dev Pauses the contract in case of an emergency.
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @dev Unpauses the contract in case of a false alarm.
     */
    function unpause() external onlyPauser {
        _unpause();
    }

    /** 
     * @dev Changes the pauser role to the selected address.
     */
    function transferPauser(address to) external onlyPauser {
        pauser = to;
    }

    /**
     * @notice THIS CONTRACT SHOULD NEVER HOLD FUNDS.
     * @dev This function only exists in case ERC20 funds are accidentally sent to the
     * contract address, and can only be called by the pauser.
     */
    function withdrawLockedTokens(address token) external onlyPauser {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(pauser, balance);
    }
    /**
     * @dev The receive function is a necessity because Aave V1 deals with ETH, whereas Aave
     * V2 deals with WETH. 
     * 
     * This function can only be called by either the WETH address upon withdrawing ETH to repay
     * an Aave V1 borrow, or from the lendingPoolCore address when redeeming aETH for ETH to deposit 
     * into awETH on Aave V2.
     */
    receive() external payable whenNotPaused {
        require(msg.sender == WETH_ADDRESS || msg.sender == coreAddress, "Migrator: Invalid ETH sender");
    }

    /**
     * @dev This function takes care of migrating aTokens from v1 to v2, and is private. It also
     * takes into account aLEND to aAAVE migration.
     *
     * @param aTokens The aTokens array passed to migrate.
     * @param aTokenAmounts aTokenAmounts determined in migrate.
     */
    function migrateCollateral(address[] memory aTokens, uint256[] memory aTokenAmounts) private whenNotPaused {

        // Loop iterates through all aTokens and migrates appropriately.
        for (uint256 i = 0; i < aTokens.length; i++) {

            // Transfer in the aTokens from the caller.
            IAToken aToken = IAToken(aTokens[i]);
            aToken.safeTransferFrom(caller, address(this), aTokenAmounts[i]);
            address underlying = aToken.underlyingAssetAddress();

            // Redeem the aTokens for their underlying assets.
            aToken.redeem(aTokenAmounts[i]);

            // If the aToken is aETH, we will receive ETH upon calling redeem.
            // This must be turned to WETH, so we deposit it into WETH and manually
            // set the underlying address to the WETH address
            if (aTokens[i] == A_ETH_ADDRESS) {
                weth.deposit{value:aTokenAmounts[i]}();
                underlying = WETH_ADDRESS;            
            } 

            // If the aToken to migrate is aLEND, migrate it to AAVE before depositing AAVE. 
            if (aTokens[i] == A_LEND_ADDRESS) {
                IERC20(underlying).approve(LEND_MIGRATOR_ADDRESS, aTokenAmounts[i]);
                lendMigrator.migrateFromLEND(aTokenAmounts[i]);
                underlying = AAVE_ADDRESS;
                uint256 aaveBalanceAfter = aTokenAmounts[i].div(100);
                IERC20(underlying).approve(address(LENDING_POOL), aaveBalanceAfter);
                LENDING_POOL.deposit(underlying, aaveBalanceAfter, caller, REF_CODE);
            } else {
                IERC20(underlying).approve(address(LENDING_POOL), aTokenAmounts[i]);
                LENDING_POOL.deposit(underlying, aTokenAmounts[i], caller, REF_CODE);
            }
        }
    }
}