// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseTransfersNative.sol";
import "./WETH9NativeWrapper.sol";
import "./BaseSwap.sol";
import "./DefinitiveAssets.sol";
import "./LLSDStrategy.sol";
import "./CompoundV3.sol";

// solhint-disable-next-line contract-name-camelcase
contract LLSD_EthereumCompoundV3Balancer_wstETH_WETH is
    LLSDStrategy,
    BaseTransfersNative,
    WETH9NativeWrapper,
    CompoundV3
{
    using DefinitiveAssets for IERC20;

    /// @dev Compound V3 Mainnet Pool Address
    address public constant COMPOUND_POOL = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    constructor(
        BaseNativeWrapperConfig memory baseNativeWrapperConfig,
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig,
        address flashloanProviderAddress
    )
        /// @dev Compound V3 Mainnet Pool Address
        CompoundV3(COMPOUND_POOL)
        LLSDStrategy(
            coreAccessControlConfig,
            coreSwapConfig,
            coreFeesConfig,
            LLSDStrategyConfig(
                /// @dev STAKING_TOKEN: WETH
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                /// @dev STAKED_TOKEN: wstETH
                0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
            ),
            flashloanProviderAddress
        )
        WETH9NativeWrapper(baseNativeWrapperConfig)
    {}

    function enter(
        uint256 flashloanAmount,
        SwapPayload calldata swapPayload,
        uint256 maxLTV
    ) external onlyWhitelisted stopGuarded nonReentrant enforceMaxLTV(maxLTV) emitEvent(FlashLoanContextType.ENTER) {
        EnterContext memory ctx = EnterContext(flashloanAmount, swapPayload, maxLTV);

        return
            flashloanAmount == 0
                ? _enterContinue(abi.encode(ctx))
                : initiateFlashLoan(
                    STAKING_TOKEN(),
                    flashloanAmount,
                    abi.encode(FlashLoanContextType.ENTER, abi.encode(ctx))
                );
    }

    function exit(
        uint256 flashloanAmount,
        uint256 repayAmount,
        uint256 decollateralizeAmount,
        SwapPayload calldata swapPayload,
        uint256 maxLTV
    ) external onlyWhitelisted stopGuarded nonReentrant enforceMaxLTV(maxLTV) emitEvent(FlashLoanContextType.EXIT) {
        ExitContext memory ctx = ExitContext(flashloanAmount, repayAmount, decollateralizeAmount, swapPayload, maxLTV);

        return
            flashloanAmount == 0
                ? _exitContinue(abi.encode(ctx))
                : initiateFlashLoan(
                    STAKING_TOKEN(),
                    flashloanAmount,
                    abi.encode(FlashLoanContextType.EXIT, abi.encode(ctx))
                );
    }

    function getCollateralToDebtPrice() external view returns (uint256, uint256) {
        // Gets price of wstETH in ETH
        (uint256 stakedAssetPriceETH, uint256 stakedAssetPricePrecision) = _getOraclePrice(STAKED_TOKEN());

        // Returns reciprocal of wstETH price to get WETH price in wstETH
        return (1e18 / stakedAssetPriceETH, 1e18 / stakedAssetPricePrecision);
    }

    function getDebtAmount() public view override returns (uint256) {
        return _getTotalVariableDebt();
    }

    function getCollateralAmount() public view override returns (uint256) {
        return _getTotalCollateral(STAKED_TOKEN());
    }

    function getLTV() public view override returns (uint256) {
        return _getLTV(STAKED_TOKEN());
    }

    function onFlashLoanReceived(
        address, // token
        uint256, // amount
        uint256, // feeAmount
        bytes memory userData
    ) internal override {
        (FlashLoanContextType ctxType, bytes memory data) = abi.decode(userData, (FlashLoanContextType, bytes));

        if (ctxType == FlashLoanContextType.ENTER) {
            return _enterContinue(data);
        }

        if (ctxType == FlashLoanContextType.EXIT) {
            return _exitContinue(data);
        }
    }

    function _enterContinue(bytes memory contextData) internal {
        EnterContext memory context = abi.decode(contextData, (EnterContext));
        address mSTAKED_TOKEN = STAKED_TOKEN();

        // Swap in to staked asset
        if (context.swapPayload.amount > 0) {
            SwapPayload[] memory swapPayloads = new SwapPayload[](1);
            swapPayloads[0] = context.swapPayload;
            _swap(swapPayloads, mSTAKED_TOKEN);
        }

        // Supply dry balance of staked token
        _supply(DefinitiveAssets.getBalance(mSTAKED_TOKEN));

        // Borrow flashloan amount for repayment
        _borrow(context.flashloanAmount);
    }

    function _exitContinue(bytes memory contextData) internal {
        ExitContext memory context = abi.decode(contextData, (ExitContext));

        // Repay debt
        _repay(context.repayAmount);

        // Decollateralize
        _decollateralize(context.decollateralizeAmount);

        // Swap out of staked asset
        if (context.swapPayload.amount > 0) {
            SwapPayload[] memory swapPayloads = new SwapPayload[](1);
            swapPayloads[0] = context.swapPayload;
            _swap(swapPayloads, STAKING_TOKEN());
        }
    }

    function _borrow(uint256 amount) internal override {
        borrow(STAKING_TOKEN(), amount);
    }

    function _decollateralize(uint256 amount) internal override {
        decollateralize(STAKED_TOKEN(), amount);
    }

    function _repay(uint256 amount) internal override {
        uint256 debtAmount = getDebtAmount();
        repay(STAKING_TOKEN(), amount > debtAmount ? debtAmount : amount);
    }

    function _supply(uint256 amount) internal override {
        supply(STAKED_TOKEN(), amount);
    }
}
