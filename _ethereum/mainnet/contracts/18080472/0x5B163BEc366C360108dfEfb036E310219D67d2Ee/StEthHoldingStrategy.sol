// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ILido.sol";
import "./ICurvePool.sol";
import "./PackedRange.sol";
import "./Strategy.sol";
import "./WethHelper.sol";

error StEthHoldingBeforeDepositCheckFailed();
error StEthHoldingBeforeRedeemalCheckFailed();
error StEthHoldingDepositSlippagesFailed();
error StEthHoldingRedeemSlippagesFailed();

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
// This is a liquid staking derivative strategy where eth is staked with Lido
// to be used for spinning up validators. Users staking share is represented by
// stETH that is minted 1:1 when staking eth.
// The strategy supports two ways to obtain the stETH
// - stake eth directly with Lido
// - buy stETH with eth on the curve steth pool
// The do-hard-worker can decide which way to use based on profitability by
// setting appropriate slippages (see slippages above).
// Since staked eth is used to spin-up validators, it cannot be unstaked. To
// exit the protocol, the strategy sells stETH for eth on the curve steth pool.
contract StEthHoldingStrategy is Strategy, WethHelper {
    using SafeERC20 for IERC20;

    int128 public constant CURVE_ETH_POOL_ETH_INDEX = 0;
    int128 public constant CURVE_ETH_POOL_STETH_INDEX = 1;

    ILido public immutable lido;
    ICurveEthPool public immutable curve;

    uint256 private _lastSharePrice;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        ILido lido_,
        ICurveEthPool curve_,
        address weth_
    ) Strategy(assetGroupRegistry_, accessControl_, assetGroupId_) WethHelper(weth_) {
        if (address(lido_) == address(0)) {
            revert ConfigurationAddressZero();
        }
        if (address(curve_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        lido = lido_;
        curve = curve_;
    }

    function initialize(string memory strategyName_) external initializer {
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
        amounts[0] = lido.balanceOf(address(this));
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](1);
            beforeDepositCheckSlippageAmounts[0] = amounts[0];

            emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
            return;
        }

        if (slippages[0] > 2) {
            revert StEthHoldingBeforeDepositCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippages[1], amounts[0])) {
            revert StEthHoldingBeforeDepositCheckFailed();
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
            revert StEthHoldingBeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert StEthHoldingBeforeRedeemalCheckFailed();
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
            revert StEthHoldingDepositSlippagesFailed();
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
            revert StEthHoldingRedeemSlippagesFailed();
        }

        uint256 stEthToSell = lido.balanceOf(address(this)) * ssts / totalSupply();
        _sellOnCurve(stEthToSell, slippage);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert StEthHoldingRedeemSlippagesFailed();
        }

        uint256 bought = _sellOnCurve(lido.balanceOf(address(this)), slippages[1]);

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

    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal override {}

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256)
    {
        return priceFeedManager.assetToUsdCustomPrice(weth, lido.balanceOf(address(this)), exchangeRates[0]);
    }

    function _stake(uint256 amount) private {
        unwrapEth(amount);

        lido.submit{value: amount}(address(0));
    }

    function _buyOnCurve(uint256 amount, uint256 slippage) private {
        unwrapEth(amount);

        uint256 bought =
            curve.exchange{value: amount}(CURVE_ETH_POOL_ETH_INDEX, CURVE_ETH_POOL_STETH_INDEX, amount, slippage);

        if (_isViewExecution()) {
            emit Slippages(true, bought, "");
        }
    }

    function _sellOnCurve(uint256 amount, uint256 slippage) private returns (uint256 bought) {
        _resetAndApprove(IERC20(address(lido)), address(curve), amount);
        bought = curve.exchange(CURVE_ETH_POOL_STETH_INDEX, CURVE_ETH_POOL_ETH_INDEX, amount, slippage);

        wrapEth(bought);

        if (_isViewExecution()) {
            emit Slippages(false, bought, "");
        }
    }

    function _getSharePrice() private view returns (uint256) {
        return lido.getPooledEthByShares(1 ether);
    }

    function _getProtocolRewardsInternal()
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {}
}
