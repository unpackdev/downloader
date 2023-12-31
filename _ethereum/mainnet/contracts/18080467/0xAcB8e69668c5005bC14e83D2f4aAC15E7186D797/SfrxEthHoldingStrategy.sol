// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFrxEthMinter.sol";
import "./ISfrxEthToken.sol";
import "./ICurvePool.sol";
import "./PackedRange.sol";
import "./Strategy.sol";
import "./WethHelper.sol";

error SfrxEthHoldingBeforeDepositCheckFailed();
error SfrxEthHoldingBeforeRedeemalCheckFailed();
error SfrxEthHoldingDepositSlippagesFailed();
error SfrxEthHoldingRedeemSlippagesFailed();

// one asset
// no rewards
// slippages
// - mode selection: slippages[0]
// - DHW with deposit: slippages[0] == 0
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _depositToProtocol: slippages[3]
// - DHW with withdrawal: slippages[0] == 1
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _redeemFromProtocol: slippages[3]
// - reallocate: slippages[0] == 2
//   - beforeDepositCheck: depositSlippages[1]
//   - _depositToProtocol: depositSlippages[2]
//   - beforeRedeemalCheck: withdrawalSlippages[1]
//   - _redeemFromProtocol: withdrawalSlippages[2]
// - redeemFast or emergencyWithdraw: slippages[0] == 3
//   - _redeemFromProtocol or _emergencyWithdrawImpl: slippages[1]
// - _depositToProtocol:
//   - if slippage == uint256 max -> stake
//     else -> buy on curve
// Description:
// This is a liquid staking derivative strategy where eth is staked with Frax
// to be used for spinning up validators.
// Frax has two tokens, frxETH and sfrxETH. The frxETH token is minted 1:1 when
// submiting eth to Frax. It cannot be redeemed back for eth and just holding
// it is not enough to be eligible for staking yield. The sfrxETH token is
// minted when depositing frxETH. The price of sfrxETH compared to frxETH is
// increasing over time based on rewards accrued by validators.
// The strategy supports two ways to obtain sfrxETH
// - mint frxETH with Frax and deposit it to get sfrxETH
// - buy frxETH on Curve frxeth pool and deposit it to get sfrxETH with Frax
// The do-hard-worker can decide which way to use based on profitability by
// setting appropriate slippages (see slippages above).
// Since frxETH is used to spin-up validators, it cannot be redeemed back for
// eth directly. To exit the protocol, the strategy redeems the frxETH from
// sfrxETH and then sells the frxETH for eth on the Curve frxeth pool.
contract SfrxEthHoldingStrategy is Strategy, WethHelper {
    using SafeERC20 for IERC20;

    int128 public constant CURVE_ETH_POOL_ETH_INDEX = 0;
    int128 public constant CURVE_ETH_POOL_FRXETH_INDEX = 1;

    IERC20 public immutable frxEthToken;
    ISfrxEthToken public immutable sfrxEthToken;
    IFrxEthMinter public immutable frxEthMinter;
    ICurveEthPool public immutable curve;

    uint256 private _lastSharePrice;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        IERC20 frxEthToken_,
        ISfrxEthToken sfrxEthToken_,
        IFrxEthMinter frxEthMinter_,
        ICurveEthPool curve_,
        address weth_
    ) Strategy(assetGroupRegistry_, accessControl_, assetGroupId_) WethHelper(weth_) {
        if (address(frxEthToken_) == address(0)) {
            revert ConfigurationAddressZero();
        }
        if (address(sfrxEthToken_) == address(0)) {
            revert ConfigurationAddressZero();
        }
        if (address(frxEthMinter_) == address(0)) {
            revert ConfigurationAddressZero();
        }
        if (address(curve_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        frxEthToken = frxEthToken_;
        sfrxEthToken = sfrxEthToken_;
        frxEthMinter = frxEthMinter_;
        curve = curve_;
    }

    function initialize(string calldata strategyName_) external initializer {
        __Strategy_init(strategyName_, NULL_ASSET_GROUP_ID);

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        if (tokens.length != 1 || tokens[0] != weth) {
            revert InvalidAssetGroup(assetGroupId());
        }

        _lastSharePrice = _getSharePrice();
    }

    function assetRatio() external pure override returns (uint256[] memory) {
        uint256[] memory _assetRatio = new uint256[](1);
        _assetRatio[0] = 1;
        return _assetRatio;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        amounts[0] = sfrxEthToken.convertToAssets(sfrxEthToken.balanceOf(address(this)));
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](1);
            beforeDepositCheckSlippageAmounts[0] = amounts[0];

            emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
            return;
        }

        if (slippages[0] > 2) {
            revert SfrxEthHoldingBeforeDepositCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippages[1], amounts[0])) {
            revert SfrxEthHoldingBeforeDepositCheckFailed();
        }
    }

    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            emit BeforeRedeemalCheckSlippages(ssts);
            return;
        }

        uint256 slippage;
        if (slippages[0] < 2) {
            slippage = slippages[2];
        } else if (slippages[0] == 2) {
            slippage = slippages[1];
        } else {
            revert SfrxEthHoldingBeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert SfrxEthHoldingBeforeRedeemalCheckFailed();
        }
    }

    function _depositToProtocol(address[] calldata, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        uint256 slippage;
        if (slippages[0] == 0) {
            slippage = slippages[3];
        } else if (slippages[0] == 2) {
            slippage = slippages[2];
        } else {
            revert SfrxEthHoldingDepositSlippagesFailed();
        }

        if (slippage == type(uint256).max) {
            _stake(amounts[0]);
        } else {
            _buyOnCurve(amounts[0], slippage);
        }
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata slippages) internal override {
        uint256 slippage;
        if (slippages[0] == 1) {
            slippage = slippages[3];
        } else if (slippages[0] == 2) {
            slippage = slippages[2];
        } else if (slippages[0] == 3) {
            slippage = slippages[1];
        } else if (_isViewExecution()) {} else {
            revert SfrxEthHoldingRedeemSlippagesFailed();
        }

        uint256 sharesToRedeem = sfrxEthToken.balanceOf(address(this)) * ssts / totalSupply();
        _sellOnCurve(sharesToRedeem, slippage);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert SfrxEthHoldingRedeemSlippagesFailed();
        }

        uint256 bought = _sellOnCurve(sfrxEthToken.balanceOf(address(this)), slippages[1]);

        IERC20(weth).safeTransfer(recipient, bought);
    }

    function _compound(address[] calldata, SwapInfo[] calldata, uint256[] calldata)
        internal
        pure
        override
        returns (int256)
    {}

    function _getYieldPercentage(int256) internal override returns (int256 baseYieldPercentage) {
        uint256 currentSharePrice = _getSharePrice();

        baseYieldPercentage = _calculateYieldPercentage(_lastSharePrice, currentSharePrice);

        _lastSharePrice = currentSharePrice;
    }

    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal pure override {}

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256)
    {
        uint256 assets = sfrxEthToken.convertToAssets(sfrxEthToken.balanceOf(address(this)));

        return priceFeedManager.assetToUsdCustomPrice(weth, assets, exchangeRates[0]);
    }

    function _stake(uint256 amount) private {
        unwrapEth(amount);

        frxEthMinter.submitAndDeposit{value: amount}(address(this));
    }

    function _buyOnCurve(uint256 amount, uint256 slippage) private {
        unwrapEth(amount);

        uint256 bought =
            curve.exchange{value: amount}(CURVE_ETH_POOL_ETH_INDEX, CURVE_ETH_POOL_FRXETH_INDEX, amount, slippage);

        _resetAndApprove(frxEthToken, address(sfrxEthToken), bought);
        sfrxEthToken.deposit(bought, address(this));

        if (_isViewExecution()) {
            emit Slippages(true, bought, "");
        }
    }

    function _sellOnCurve(uint256 amount, uint256 slippage) private returns (uint256 bought) {
        uint256 withdrawn = sfrxEthToken.redeem(amount, address(this), address(this));

        _resetAndApprove(IERC20(address(frxEthToken)), address(curve), withdrawn);
        bought = curve.exchange(CURVE_ETH_POOL_FRXETH_INDEX, CURVE_ETH_POOL_ETH_INDEX, withdrawn, slippage);

        wrapEth(bought);

        if (_isViewExecution()) {
            emit Slippages(false, bought, "");
        }
    }

    function _getSharePrice() private view returns (uint256) {
        return sfrxEthToken.convertToAssets(1 ether);
    }

    function _getProtocolRewardsInternal()
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {}
}
