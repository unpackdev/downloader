// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILiquidation.sol";
import "./IMToken.sol";
import "./IAccessControl.sol";
import "./IERC20.sol";
import "./IPool.sol";
import "./IV3SwapRouter.sol";

interface IFlasher is IAccessControl {
    event Withdraw(address token, address to, uint256 amount);
    event NewLiquidation(ILiquidation liquidation);
    event NewOracle(IPriceOracle oracle);
    event NewTreasury(address newTreasuryAddress);
    event NewDefaultSurplusAsset(address newDefaultSurplusAsset);
    event NewPoolAddressesProvider(IPoolAddressesProvider liquidation);
    event NewSwapRouter(IV3SwapRouter router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedGatekeeper(address bot);
    event NewAllowedSurplusAsset(IERC20 surplusAsset);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedGatekeeperRemoved(address bot);
    event AllowedSurplusAssetRemoved(IERC20 surplusAsset);
    event MulticallSwap(IERC20 tokenIn, IERC20 tokenOut, uint256 spentAmount, uint256 receivedAmount);
    event ExactInputSingleSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 spentAmount,
        uint256 receivedAmount,
        uint256 poolFee,
        uint256 slippage
    );
    event SurplusTransfer(IERC20 surplusAsset, address treasuryAddress, uint256 transferAmount);
    event TokenOutDeviationChanged(uint256 oldValue, uint256 newValue);

    struct SurplusSwapData {
        uint256 poolFeeTick;
        uint256 slippage;
    }

    struct AaveFlashCallbackData {
        IMToken seizeMarket;
        IMToken repayMarket;
        address borrower;
        uint256 repayAmount;
        bytes mainSwapData;
        bytes surplusSwapData;
    }

    /**
     * @notice get AAVE pool addresses provider contract
     */
    function aavePoolAddressesProvider() external view returns (IPoolAddressesProvider);

    /**
     * @notice get Uniswap SwapRouter contract
     */
    function swapRouter() external view returns (IV3SwapRouter);

    /**
     * @notice get liquidation contract
     */
    function liquidation() external view returns (ILiquidation);

    /**
     * @notice get Price oracle contract
     */
    function oracle() external view returns (IPriceOracle);

    /**
     * @notice get token address that is used as default surplus asset
     */
    function defaultSurplusAsset() external view returns (address);

    /**
     * @notice get treasury address
     */
    function treasuryAddress() external view returns (address);

    /**
     * @notice get whitelist for ERC20 token that can be used as surplus
     */
    function allowedSurplusAssets(IERC20) external view returns (bool);

    /**
     * @notice get whitelist for users who can be a withdrawal recipients
     */
    function allowedWithdrawReceivers(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
    @notice Initiates a flash loan from Aave, liquidates an unsafe loan,
            and handles additional swap operations based on `mainSwapData` and `surplusSwapData`.
            Transfers surplus asset to the treasury
    @param seizeMarket Market from which the account's collateral will be seized
    @param repayMarket Market from which the account's debt will be repaid
    @param borrower The address of the borrower with the unsafe loan.
    @param repayAmount Amount of debt to be repaid
    @param mainSwapData The encoded data for executing the swap of seized assets to repaid assets after liquidation.
           Required if (seizeAsset != repayAsset)
    @param surplusSwapData The encoded data for executing surplus swap operations.
           Required if seized asset is not in allowedSurplusAssets list.
    @dev RESTRICTION: GATEKEEPER only
    */
    function flashLiquidation(
        IMToken repayMarket,
        IMToken seizeMarket,
        address borrower,
        uint256 repayAmount,
        bytes calldata mainSwapData,
        bytes calldata surplusSwapData
    ) external;

    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     * @dev RESTRICTION: AAVE pool proxy contract only
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Recipient address (RESTRICTION: allowed receivers only)
     * @dev RESTRICTION: Admin only
     */
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external;

    /**
     * @notice Set new tokenOutDeviation
     * @dev RESTRICTION: Admin only
     */
    function setTokenOutDeviation(uint256 newValue_) external;

    /**
     * @notice Set new ILiquidation contract
     * @dev RESTRICTION: Admin only
     */
    function setLiquidationAddress(ILiquidation liquidationContract) external;

    /**
     * @notice Set new Uniswap V3: Router 2 contract
     * @dev RESTRICTION: Admin only
     */
    function setRouterAddress(IV3SwapRouter router) external;

    /**
     * @notice Set new AAVE pool addresses provider contract
     * @dev RESTRICTION: Admin only
     */
    function setPoolAddressesProvider(IPoolAddressesProvider newAddressesProviderContract) external;

    /**
     * @notice Set new Price oracle contract
     * @dev RESTRICTION: Admin only
     */
    function setOracleAddress(IPriceOracle newOracleContract) external;

    /**
     * @notice Set new treasury address
     * @dev RESTRICTION: Admin only
     */
    function setTreasuryAddress(address newTreasuryAddress) external;

    /**
     * @notice Set default surplus asset address
     * @dev RESTRICTION: Admin only
     */
    function setDefaultSurplusAsset(address newDefaultSurplusAsset) external;

    /**
     * @notice Add new withdraw receiver address to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedReceiver(address receiver) external;

    /**
     * @notice Add new allowed surplus asset
     * @dev RESTRICTION: Admin only
     */
    function addAllowedSurplusAsset(IERC20 newSurplusAsset) external;

    /**
     * @notice Grant GATEKEEPER role to the new address
     * @dev RESTRICTION: Admin only
     */
    function addAllowedGatekeeper(address newGatekeeper) external;

    /**
     * @notice Remove surplus asset from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedSurplusAsset(IERC20 surplusAsset) external;

    /**
     * @notice Remove withdraw receiver address from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedReceiver(address receiver) external;

    /**
     * @notice Revoke GATEKEEPER role from the address
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedGatekeeper(address gatekeeper) external;
}
