// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseTransfersNative.sol";
import "./WETH9NativeWrapper.sol";
import "./BaseSwap.sol";
import "./DefinitiveAssets.sol";
import "./LLSDStrategy.sol";
import "./BalancerFlashloanBase.sol";
import "./AaveV3Helper.sol";

// solhint-disable-next-line contract-name-camelcase
contract LLSD_EthereumAaveV3Balancer_wstETH_WETH is
    LLSDStrategy,
    BaseTransfersNative,
    WETH9NativeWrapper,
    BalancerFlashloanBase
{
    using DefinitiveAssets for IERC20;

    /// @dev Aave V3 Mainnet Pool Address
    /// @dev https://docs.aave.com/developers/deployed-contracts/v3-mainnet/ethereum-mainnet
    address public constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    constructor(
        BaseNativeWrapperConfig memory baseNativeWrapperConfig,
        CoreAccessControlConfig memory coreAccessControlConfig,
        CoreSwapConfig memory coreSwapConfig,
        CoreFeesConfig memory coreFeesConfig
    )
        LLSDStrategy(
            coreAccessControlConfig,
            coreSwapConfig,
            coreFeesConfig,
            LLSDStrategyConfig(
                /// @dev STAKING_TOKEN: WETH
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                /// @dev STAKED_TOKEN: wstETH
                0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
            )
        )
        WETH9NativeWrapper(baseNativeWrapperConfig)
    {
        // Enable EMode to ETH Correlated to increase LTV to 90%
        AaveV3Helper.setEMode(AAVE_V3_POOL, 1);
    }

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

    function setEMode(uint8 categoryId) external onlyWhitelisted {
        AaveV3Helper.setEMode(AAVE_V3_POOL, categoryId);
    }

    function getCollateralToDebtPrice() external view returns (uint256, uint256) {
        return AaveV3Helper.getOraclePriceRatio(AAVE_V3_POOL, STAKING_TOKEN(), STAKED_TOKEN());
    }

    function getDebtAmount() public view override returns (uint256) {
        return AaveV3Helper.getTotalVariableDebt(AAVE_V3_POOL, STAKING_TOKEN());
    }

    function getCollateralAmount() public view override returns (uint256) {
        return AaveV3Helper.getTotalCollateral(AAVE_V3_POOL, STAKED_TOKEN());
    }

    function getLTV() public view override returns (uint256) {
        return AaveV3Helper.getLTV(AAVE_V3_POOL, address(this));
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
        AaveV3Helper.borrow(AAVE_V3_POOL, STAKING_TOKEN(), amount, DataTypes.InterestRateMode.VARIABLE, address(this));
    }

    function _decollateralize(uint256 amount) internal override {
        AaveV3Helper.decollateralize(AAVE_V3_POOL, STAKED_TOKEN(), amount, address(this));
    }

    function _repay(uint256 amount) internal override {
        uint256 debtAmount = getDebtAmount();
        AaveV3Helper.repay(
            AAVE_V3_POOL,
            STAKING_TOKEN(),
            amount > debtAmount ? debtAmount : amount,
            DataTypes.InterestRateMode.VARIABLE,
            address(this)
        );
    }

    function _supply(uint256 amount) internal override {
        AaveV3Helper.supply(AAVE_V3_POOL, STAKED_TOKEN(), amount, address(this));
    }
}
