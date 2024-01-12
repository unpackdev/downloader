// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./FlashLoanReceiverBaseV2.sol";
import "./ILendingPoolAddressesProviderV2.sol";
import "./ILendingPoolV2.sol";
import "./IBalancerVaultV2.sol";
import "./IBSLendingPair.sol";
import "./IBSVault.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title LiquidationHelper
/// @author @conlot-crypto
/// @notice Element finance Principal(EFP) token Liquidator Contract.
/// A contract that takes the flash loan from Aave.
/// Repays the debt and liquidates the collateral via the EFP pools.
/// Then uses the remaining funds to repay back the flashloan and keeps the rest as profit
/// For USDC PT/USDC, wBTC PT/wBTC, DAI PT/DAI pairs
///
////////////////////////////////////////////////////////////////////////////////////////////

contract LiquidationHelper is FlashLoanReceiverBaseV2 {
    struct LiquidationCallLocalVars {
        uint256 initFlashBorrowedBalance;
        uint256 diffFlashBorrowedBalance;
        uint256 initCollateralBalance;
        uint256 diffCollateralBalance;
        uint256 flashLoanDebt;
        uint256 soldAmount;
        uint256 remainingCollateralTokens;
        uint256 borrowedAssetLeftovers;
    }

    struct FlashLoanParams {
        address pair;
        address collateralAsset;
        address borrowedAsset;
        address initiator;
        address[] borrowers;
    }

    /// @dev Balancer V2 Vault
    IBalancerVaultV2 public immutable balancerVault;

    /// @dev warp.finanace vault
    IBSVault public immutable warpVault;

    constructor(
        address _aaveAddressProvider,
        IBalancerVaultV2 _balancerVault,
        IBSVault _warpVault
    ) public FlashLoanReceiverBaseV2(_aaveAddressProvider) {
        require(address(_balancerVault) != address(0), "Invalid Balancer Vault");
        require(address(_warpVault) != address(0), "Invalid Warp Vault");

        balancerVault = _balancerVault;
        warpVault = _warpVault;
    }

    /**
     * @dev
     * @param flashBorrowedAmount flash borrowed amount from Aave
     * @param params FlashLoanParams parameters
     * @param premium FlashLoanBorrow fee
     */
    function _liquidateAndSwap(
        uint256 flashBorrowedAmount,
        FlashLoanParams memory params,
        uint256 premium
    ) internal {
        LiquidationCallLocalVars memory vars;
        vars.initCollateralBalance = IERC20(params.collateralAsset).balanceOf(address(this));

        vars.initFlashBorrowedBalance = IERC20(params.borrowedAsset).balanceOf(address(this));

        // Track leftover balance to rescue funds in case of external transfers into this contract
        vars.borrowedAssetLeftovers = vars.initFlashBorrowedBalance - flashBorrowedAmount;

        vars.flashLoanDebt = flashBorrowedAmount + premium;

        // approve to deposit into vault
        IERC20(params.borrowedAsset).approve(address(warpVault), flashBorrowedAmount);

        // deposit borrwoed asset into warp vault
        warpVault.deposit(
            IERC20(params.borrowedAsset),
            address(this),
            address(this),
            flashBorrowedAmount
        );

        // approve pair to transfer tokens
        warpVault.approveContract(address(this), address(params.pair), true, 0, 0, 0);

        // Liquidate the user position and release the underlying collateral
        for (uint256 i = 0; i < params.borrowers.length; i++) {
            IBSLendingPair(params.pair).liquidate(params.borrowers[i]);
        }

        // withdraw borrowasset from warp vault
        warpVault.withdraw(
            IERC20(params.borrowedAsset),
            address(this),
            address(this),
            warpVault.balanceOf(IERC20(params.borrowedAsset), address(this))
        );

        // withdraw collateral from warp vault
        uint256 collateralBalanceAfter =
            warpVault.withdraw(
                IERC20(params.collateralAsset),
                address(this),
                address(this),
                warpVault.balanceOf(IERC20(params.collateralAsset), address(this))
            );

        // Track only collateral released, not current asset balance of the contract
        vars.diffCollateralBalance = collateralBalanceAfter - vars.initCollateralBalance;

        // Discover flash loan balance after the liquidation
        uint256 flashBorrowedAssetAfter = IERC20(params.borrowedAsset).balanceOf(address(this));

        // Use only flash loan borrowed assets, not current asset balance of the contract
        vars.diffFlashBorrowedBalance = flashBorrowedAssetAfter - vars.borrowedAssetLeftovers;

        // Swap released collateral into the debt asset, to repay the flash loan
        // @TODO improve the swapping of collateral for borrowed asset by calculating the minimum expected collateral offchain
        vars.soldAmount = _swapTokensForExactTokens(
            params.collateralAsset,
            params.borrowedAsset,
            vars.diffCollateralBalance,
            vars.flashLoanDebt - vars.diffFlashBorrowedBalance
        );

        vars.remainingCollateralTokens = vars.diffCollateralBalance - vars.soldAmount;

        // Allow repay of flash loan
        IERC20(params.borrowedAsset).approve(address(LENDING_POOL), vars.flashLoanDebt);

        // Transfer remaining collateral tokens to initiator
        if (vars.remainingCollateralTokens > 0) {
            IERC20(params.collateralAsset).transfer(
                params.initiator,
                vars.remainingCollateralTokens
            );
        }

        // Transfer remaining borrowed tokens ot initiator
        uint256 availableBorrowedAssetAmount =
            IERC20(params.borrowedAsset).balanceOf(address(this));
        if (availableBorrowedAssetAmount > vars.flashLoanDebt) {
            IERC20(params.borrowedAsset).transfer(
                params.initiator,
                availableBorrowedAssetAmount - vars.flashLoanDebt
            );
        }
    }

    /**
     * @dev swap Tokens on Balancer vault
     * @param assetToSwapFrom Origin asset
     * @param assetToSwapTo Destination asset
     * @param maxAmountToSwap Max amount of `assetToSwapFrom` allowed to be swapped
     * @param amountToReceive amount of `assetToSwapTo` to receive
     * @return amountToSwapped amount swapped
     */
    function _swapTokensForExactTokens(
        address assetToSwapFrom,
        address assetToSwapTo,
        uint256 maxAmountToSwap,
        uint256 amountToReceive
    ) internal returns (uint256 amountToSwapped) {
        // approve tokens to send to balancer vault to swap
        IERC20(assetToSwapFrom).approve(address(balancerVault), maxAmountToSwap);

        // purchase amountToReceive from balancer vault via swap
        amountToSwapped = balancerVault.swap(
            IBalancerVaultV2.SingleSwap({
                poolId: "",
                kind: IBalancerVaultV2.SwapKind.GIVEN_IN,
                assetIn: assetToSwapFrom,
                assetOut: assetToSwapTo,
                amount: maxAmountToSwap,
                userData: "0x00"
            }),
            IBalancerVaultV2.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            amountToReceive,
            block.timestamp + 1 hours
        );
    }

    /**
     * @dev Decodes the information encoded in the flash loan params
     * @param params Additional variadic field to include extra params
     * @return FlashLoanParams struct containing decoded params
     */
    function _decodeParams(bytes memory params) internal pure returns (FlashLoanParams memory) {
        (
            address pair,
            address collateralAsset,
            address borrowedAsset,
            address initiator,
            address[] memory borrowers
        ) = abi.decode(params, (address, address, address, address, address[]));

        return FlashLoanParams(pair, collateralAsset, borrowedAsset, initiator, borrowers);
    }

    /**
     * @dev This function must be called only be the LENDING_POOL and takes care of repaying
     * active debt positions, migrating collateral and incurring new V2 debt token debt.
     *
     * @param assets The array of flash loaned assets used to repay debts.
     * @param amounts The array of flash loaned asset amounts used to repay debts.
     * @param premiums The array of premiums incurred as additional debts.
     * @param initiator The address that initiated the flash loan, unused.
     * @param params The byte array containing
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        FlashLoanParams memory decodedParams = _decodeParams(params);

        require(
            assets.length == 1 &&
                assets[0] == decodedParams.borrowedAsset &&
                decodedParams.borrowers.length > 0,
            "INCONSISTENT_PARAMS"
        );

        _liquidateAndSwap(amounts[0], decodedParams, premiums[0]);

        return true;
    }

    /**
     * @dev This function will trigger logic to flashloan borrow and liquidate
     *
     * @param pair warp finance pair
     * @param borrowers who will be liquidated
     * @param amount of tokens to borrow & liquidate
     */
    function flashLoanToLiquidate(
        IBSLendingPair pair,
        address[] memory borrowers,
        uint256 amount
    ) public {
        require(address(pair) != address(0), "Invalid Pair");

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 = no debt (flash), 1 = stable, 2 = variable

        address[] memory assets = new address[](1);
        assets[0] = address(pair.asset());

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        bytes memory params =
            abi.encode(
                address(pair),
                pair.collateralAsset(),
                pair.asset(),
                msg.sender,
                amount,
                borrowers
            );

        LENDING_POOL.flashLoan(
            address(this), // receiverAddress
            assets,
            amounts,
            modes,
            address(this), // onBehalfOf
            params,
            0 // referralCode
        );
    }
}
