//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./IFlashLoanSimpleReceiver.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";

import "./ERC20.sol";
import "./SafeERC20.sol";

import "./LowGasSafeMath.sol";
import "./TransferHelper.sol";

import "./I1InchAggregatorV5.sol";
import "./ITermPriceOracle.sol";
import "./ITermRepoCollateralManager.sol";
import "./ITermRepoServicer.sol";
import "./ISavingsDai.sol";
import "./IWstbt.sol";


import "./ExponentialNoError.sol";
import "./TermFlashDefaultSubmission1Inch.sol";
import "./OneInchSwapDescription.sol";

contract TermFlashShortfallLiquidatorFlashSwapAave is IFlashLoanSimpleReceiver, ExponentialNoError {
    using SafeERC20 for ERC20;
    using LowGasSafeMath for uint256;

    address public constant SDAI_ADDRESS = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address public constant WSTBT_ADDRESS = 0x288A8005C53632d920045b7C7c2e54A3f1Bc4C83;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    I1InchAggregatorV5 immutable oneInchAggregator; 
    address immutable liquidatorWallet;
    ITermPriceOracle immutable priceOracle;


    constructor(address lendingPoolAddressProvider_, address oneInchAggregatorV5_, address priceOracle_, address liquidatorWallet_){
        require(
            address(lendingPoolAddressProvider_) != address(0),
            "lendingPoolAddressProvider_ cannot be 0"
        );
        require(
            address(oneInchAggregatorV5_) != address(0),
            "oneInchAggregatorV5_ cannot be 0"
        );
        require(
            address(priceOracle_) != address(0),
            "priceOracle_ cannot be 0"
        );
        require(
            address(liquidatorWallet_) != address(0),
            "liquidatorWallet_ cannot be 0"
        );
        ADDRESSES_PROVIDER = IPoolAddressesProvider(lendingPoolAddressProvider_); // mainnet address, for other addresses: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        oneInchAggregator = I1InchAggregatorV5(oneInchAggregatorV5_);
        liquidatorWallet = liquidatorWallet_;
        priceOracle = ITermPriceOracle(priceOracle_);
    }

    function flashLiquidate(TermFlashDefaultSubmission1Inch calldata flashDefaultSubmission) external {
        address receiverAddress = address(this);

        bytes memory params = abi.encode(flashDefaultSubmission); // Add any necessary parameters
        uint16 referralCode = 0;

        POOL.flashLoanSimple(receiverAddress, flashDefaultSubmission.repaymentToken, flashDefaultSubmission.coverAmount, params, referralCode);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        TermFlashDefaultSubmission1Inch memory liquidationParams = abi.decode(params, (TermFlashDefaultSubmission1Inch));

        TransferHelper.safeApprove(
            asset,
            liquidationParams.termRepoLocker,
            liquidationParams.coverAmount
        );

        _batchLiquidate(liquidationParams.termRepoCollateralManager, liquidationParams.borrower,liquidationParams.coverAmount);
        
        (address oneInchInputAsset, uint256 purchaseCurrencyReturnAmount) = _oneInchSwap(liquidationParams.oneInchSwapCalldata, liquidationParams.collateralToken, liquidationParams.unwrapCollateralToken);
        
        _finalSwapTransfers(amount, premium, purchaseCurrencyReturnAmount, asset, oneInchInputAsset);
        return true;
    }

    function flushToLiquidatorWallet(address tokenAddr) external {
        ERC20 token = ERC20(
            tokenAddr
        );
        uint256 tokenBalance = token.balanceOf(address(this));
        TransferHelper.safeTransfer(tokenAddr, liquidatorWallet, tokenBalance);
    }


    function maxLiquidationRepayment(
        ITermRepoCollateralManager termRepoCollateralManager,
        ITermRepoServicer termRepoServicer,
        address borrower,
        address repayTokenAddr,
        address collateralTokenAddr
    ) external view returns (uint256) {
        uint256 deMinimisMarginThreshold = termRepoCollateralManager
            .deMinimisMarginThreshold();
        uint256 liquidatedDamage = termRepoCollateralManager.liquidatedDamages(
            collateralTokenAddr
        );
        uint256 initialCollateralRatio = termRepoCollateralManager
            .initialCollateralRatios(collateralTokenAddr);
        uint256 netExposureCap = termRepoCollateralManager
            .netExposureCapOnLiquidation();

        ERC20 repayToken = ERC20(repayTokenAddr);
        ERC20 collateralToken = ERC20(collateralTokenAddr);

        uint256 borrowBalance = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);
        uint256 collateralBalance = termRepoCollateralManager
            .getCollateralBalance(borrower, collateralTokenAddr);
        Exp memory borrowBalanceUSD = priceOracle.usdValueOfTokens(
            repayTokenAddr,
            borrowBalance
        );
        uint256 borrowerCollateralUSDValue = termRepoCollateralManager
            .getCollateralMarketValue(borrower);

        if (
            borrowBalanceUSD.mantissa + deMinimisMarginThreshold >
            borrowerCollateralUSDValue
        ) {
            return
                _maxDeminimisLiquidationPayment(
                    collateralToken,
                    repayToken,
                    borrowBalance,
                    collateralBalance,
                    liquidatedDamage
                );
        }

        return
            _maxRepaymentWithinNetExposureCap(
                repayToken,
                borrowBalanceUSD,
                borrowerCollateralUSDValue,
                liquidatedDamage,
                initialCollateralRatio,
                netExposureCap
            );
    }

    function _maxDeminimisLiquidationPayment(
        ERC20 collateralToken,
        ERC20 repayToken,
        uint256 borrowBalance,
        uint256 collateralBalance,
        uint256 liquidatedDamage
    ) internal view returns (uint256) {
        Exp memory collateralAmountWithoutDiscount = div_(
            Exp({mantissa: collateralBalance * expScale}),
            add_(Exp({mantissa: expScale}), Exp({mantissa: liquidatedDamage}))
        );
        Exp memory usdValueOfCollateralRepaidFor = mul_(
            collateralAmountWithoutDiscount,
            priceOracle.usdValueOfTokens(
                address(collateralToken),
                10 ** (collateralToken.decimals())
            )
        );

        uint256 maxLiquidationRepaymentForCollateralBalance = truncate(
            div_(
                usdValueOfCollateralRepaidFor,
                priceOracle.usdValueOfTokens(
                    address(repayToken),
                    10 ** (repayToken.decimals())
                )
            )
        );

        return
            maxLiquidationRepaymentForCollateralBalance < borrowBalance
                ? maxLiquidationRepaymentForCollateralBalance
                : borrowBalance;
    }

    function _maxRepaymentWithinNetExposureCap(
        ERC20 repayToken,
        Exp memory borrowBalanceUSD,
        uint256 collateralUSDValue,
        uint256 liquidatedDamage,
        uint256 initialCollateralRatio,
        uint256 netExposureCap
    ) internal view returns (uint256) {
        uint8 repayTokenDecimals = repayToken.decimals();
        address repayTokenAddress = address(repayToken);
        Exp memory netExposureCapRatioMultiplier = add_(
            Exp({mantissa: expScale}),
            Exp({mantissa: netExposureCap})
        );

        Exp memory liquidatedDamageDividedByInitialCollatRatioMultiplier = div_(
            add_(Exp({mantissa: expScale}), Exp({mantissa: liquidatedDamage})),
            Exp({mantissa: initialCollateralRatio})
        );

        Exp memory currentCollateralBalanceHaircut = div_(
            Exp({mantissa: collateralUSDValue}),
            Exp({mantissa: initialCollateralRatio})
        );

        Exp memory currentBorrowBalanceHaircut = mul_(
            borrowBalanceUSD,
            netExposureCapRatioMultiplier
        );

        Exp memory currentHaircutDifference = sub_(
            currentBorrowBalanceHaircut,
            currentCollateralBalanceHaircut
        );

        Exp memory maxRepaymentAmountMultiplier = mul_(
            priceOracle.usdValueOfTokens(
                repayTokenAddress,
                10 ** repayTokenDecimals
            ),
            sub_(
                netExposureCapRatioMultiplier,
                liquidatedDamageDividedByInitialCollatRatioMultiplier
            )
        );

        Exp memory maxRepaymentAmount = div_(
            currentHaircutDifference,
            maxRepaymentAmountMultiplier
        );

        return maxRepaymentAmount.mantissa / 10 ** (18 - repayTokenDecimals);
    }

    function _batchLiquidate(address collateralManager, address borrower, uint256 coverAmount) internal {
        ITermRepoCollateralManager termRepoCollateralManager = ITermRepoCollateralManager(
            collateralManager
        );

        uint256[] memory liquidationCoverAmounts = new uint256[](1);
        liquidationCoverAmounts[0] = coverAmount;

        termRepoCollateralManager.batchLiquidation(
            borrower,
            liquidationCoverAmounts
        );

    }

    function _oneInchSwap (bytes memory oneInchSwapCalldata, address collateralToken, bool unwrapCollateralToken) internal returns(address, uint256) {
        (address executor, OneInchSwapDescription memory desc, bytes memory permit, bytes memory data) = abi.decode(oneInchSwapCalldata, (address, OneInchSwapDescription, bytes, bytes));

        address oneInchInputAsset = _oneInchSwapPrep(collateralToken, unwrapCollateralToken);

        (uint256 purchaseCurrencyReturnAmount, ) = oneInchAggregator.swap(executor, desc, permit, data);
        return (oneInchInputAsset, purchaseCurrencyReturnAmount);
    }

    function _oneInchSwapPrep(address collateralTokenAddr, bool unwrapCollateralToken ) internal returns (address) {
         ERC20 collateralToken = ERC20(
            collateralTokenAddr
        );

        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        address oneInchInputAsset;
        uint256 amount1InchInputAsset;
        if (unwrapCollateralToken){
            (oneInchInputAsset, amount1InchInputAsset) = _unwrapCollateralToken(collateralTokenAddr, collateralBalance);
        }
        else {
            oneInchInputAsset = collateralTokenAddr;
            amount1InchInputAsset = collateralBalance;
        }

        TransferHelper.safeApprove(
            oneInchInputAsset,
            address(oneInchAggregator),
            amount1InchInputAsset
        );

        return oneInchInputAsset;
    }

    function _unwrapCollateralToken(address collateralToken, uint256 collateralAmount) internal returns (address, uint256){
        if (collateralToken == SDAI_ADDRESS) {
            ISavingsDai sDai = ISavingsDai(collateralToken);
            uint256 shares = sDai.redeem(collateralAmount, address(this), address(this));
            return (address(sDai.dai()), shares);
        }
        else if (collateralToken == WSTBT_ADDRESS) {
            IWstbt wstbt = IWstbt(collateralToken);
            uint stbtAmount = wstbt.unwrap(collateralAmount);
            return (wstbt.stbtAddress(), uint256(stbtAmount));
        }
    }

    function _finalSwapTransfers(uint256 amount, uint256 premium, uint256 purchaseCurrencyReturnAmount, address repaymentAsset, address oneInchInputAsset) internal {
          // Amount to Repay the flash loan
        uint256 amountOwing = amount + premium;


        // Transfer extra purchase currency to liquidator wallet
        uint256 purchaseCurrencyToLiquidator = LowGasSafeMath.sub(
                    purchaseCurrencyReturnAmount,
                    amountOwing
        );
        TransferHelper.safeTransfer(repaymentAsset, liquidatorWallet, purchaseCurrencyToLiquidator);

        // Transfer extra 1inch input currency to liquidator wallet
        ERC20 oneInchInputAssetERC20 = ERC20(
            oneInchInputAsset
        );

        uint256 oneInchInputAssetBalance = oneInchInputAssetERC20.balanceOf(address(this));
        TransferHelper.safeTransfer(oneInchInputAsset, liquidatorWallet, oneInchInputAssetBalance);


        //Approve to repay flash loan
        TransferHelper.safeApprove(
            repaymentAsset,
            address(POOL),
            amountOwing
        );
    }

}