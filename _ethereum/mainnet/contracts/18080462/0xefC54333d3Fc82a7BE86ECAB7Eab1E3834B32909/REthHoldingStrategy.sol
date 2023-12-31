// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IREthToken.sol";
import "./IRocketSwapRouter.sol";
import "./PackedRange.sol";
import "./Strategy.sol";
import "./WethHelper.sol";

error REthHoldingBeforeDepositCheckFailed();
error REthHoldingBeforeRedeemalCheckFailed();
error REthHoldingDepositSlippagesFailed();
error REthHoldingRedeemSlippagesFailed();

// one asset
// no rewards
// slippages
// - mode selection: slippages[0]
// - DHW with deposit: slippages[0] == 0
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _depositToProtocol: slippages[3..6]
// - DHW with withdrawal: slippages[0] == 1
//   - beforeDepositCheck: slippages[1]
//   - beforeRedeemalCheck: slippages[2]
//   - _redeemFromProtocol: slippages[3..6]
// - reallocate: slippages[0] == 2
//   - beforeDepositCheck: depositSlippages[1]
//   - _depositToProtocol: depositSlippages[2..5]
//   - beforeRedeemalCheck: withdrawalSlippages[1]
//   - _redeemFromProtocol: withdrawalSlippages[2..5]
// - redeemFast or emergencyWithdraw: slippages[0] == 3
//   - _redeemFromProtocol or _emergencyWithdrawImpl: slippages[1..4]
// - deposit and withdrawals from protocol require four slippages:
//   - 1: portion to swap on uniswap
//   - 2: portion to swap on balancer
//   - 3: min out
//   - 4: ideal out
// Description:
// This is a liquid staking derivative strategy where eth is staked with Rocket
// pool to be used for spinning up validators. Users staking share is
// represented by rETH. The value of rETH compared to eth is growing with
// validation rewards collected by validators spinned up using the staked eth.
// The strategy uses the Rocket swap router to buy and sell rETH for eth. The
// swap calls have four parameters that control how exactly the swap takes
// place; portion to swap on Uniswap, portion to swap on Balancer, minimal out
// and ideal out. If ideal out is less then or equal to the internal rETH/eth
// price, the router will swap as much as possible internally. What cannot be
// swapped internally, will be swapped on Uniswap and Balancer, based on
// portions specified. Note that the portions are arbitrary numbers, what
// matters is just their ratio. At the end, the swapper checks if final swapped
// amount is at least min out, otherwise the transaction reverts. These
// parameters are passed in as slippages (see above for details).
contract REthHoldingStrategy is Strategy, WethHelper {
    using SafeERC20 for IERC20;

    IRocketSwapRouter public immutable rocketSwapRouter;
    IREthToken public immutable rEthToken;

    uint256 private _lastSharePrice;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        IRocketSwapRouter rocketSwapRouter_,
        address weth_
    ) Strategy(assetGroupRegistry_, accessControl_, assetGroupId_) WethHelper(weth_) {
        if (address(rocketSwapRouter_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        rocketSwapRouter = rocketSwapRouter_;

        rEthToken = IREthToken(rocketSwapRouter_.rETH());
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
        amounts[0] = rEthToken.getEthValue(rEthToken.balanceOf(address(this)));
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public override {
        if (_isViewExecution()) {
            uint256[] memory beforeDepositCheckSlippageAmounts = new uint256[](1);
            beforeDepositCheckSlippageAmounts[0] = amounts[0];

            emit BeforeDepositCheckSlippages(beforeDepositCheckSlippageAmounts);
            return;
        }

        if (slippages[0] > 2) {
            revert REthHoldingBeforeDepositCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippages[1], amounts[0])) {
            revert REthHoldingBeforeDepositCheckFailed();
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
            revert REthHoldingBeforeRedeemalCheckFailed();
        }

        if (!PackedRange.isWithinRange(slippage, ssts)) {
            revert REthHoldingBeforeRedeemalCheckFailed();
        }
    }

    function _depositToProtocol(address[] calldata, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        override
    {
        uint256 slippageOffset;
        if (slippages[0] == 0) {
            slippageOffset = 3;
        } else if (slippages[0] == 2) {
            slippageOffset = 2;
        } else {
            revert REthHoldingDepositSlippagesFailed();
        }

        _depositInternal(amounts[0], slippages, slippageOffset);
    }

    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata slippages) internal override {
        uint256 slippageOffset;
        if (slippages[0] == 1) {
            slippageOffset = 3;
        } else if (slippages[0] == 2) {
            slippageOffset = 2;
        } else if (slippages[0] == 3) {
            slippageOffset = 1;
        } else if (slippages[0] == 0 && _isViewExecution()) {
            slippageOffset = 3;
        } else {
            revert REthHoldingRedeemSlippagesFailed();
        }

        uint256 sharesToRedeem = rEthToken.balanceOf(address(this)) * ssts / totalSupply();
        _redeemInternal(sharesToRedeem, slippages, slippageOffset);
    }

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal override {
        if (slippages[0] != 3) {
            revert REthHoldingRedeemSlippagesFailed();
        }

        uint256 bought = _redeemInternal(rEthToken.balanceOf(address(this)), slippages, 1);

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
        uint256 assets = rEthToken.getEthValue(rEthToken.balanceOf(address(this)));

        return priceFeedManager.assetToUsdCustomPrice(weth, assets, exchangeRates[0]);
    }

    function _depositInternal(uint256 amount, uint256[] memory slippages, uint256 startingSlippage)
        private
        returns (uint256 bought)
    {
        if (_isViewExecution()) {
            // optimize first
            (uint256[2] memory portions, uint256 amountOut) = rocketSwapRouter.optimiseSwapTo(amount, 10);

            slippages[startingSlippage] = portions[0];
            slippages[startingSlippage + 1] = portions[1];
            slippages[startingSlippage + 2] = amountOut;
            slippages[startingSlippage + 3] = amountOut;

            uint256[] memory depositSlippages = new uint256[](4);
            depositSlippages[0] = portions[0];
            depositSlippages[1] = portions[1];
            depositSlippages[2] = amountOut;
            depositSlippages[3] = amountOut;

            emit Slippages(true, 0, abi.encode(depositSlippages));
        }

        unwrapEth(amount);

        bought = rEthToken.balanceOf(address(this));

        rocketSwapRouter.swapTo{value: amount}(
            slippages[startingSlippage],
            slippages[startingSlippage + 1],
            slippages[startingSlippage + 2],
            slippages[startingSlippage + 3]
        );

        bought = rEthToken.balanceOf(address(this)) - bought;
    }

    function _redeemInternal(uint256 amount, uint256[] memory slippages, uint256 startingSlippage)
        private
        returns (uint256 bought)
    {
        if (_isViewExecution()) {
            // optimize first
            (uint256[2] memory portions, uint256 amountOut) = rocketSwapRouter.optimiseSwapFrom(amount, 10);

            slippages[startingSlippage] = portions[0];
            slippages[startingSlippage + 1] = portions[1];
            slippages[startingSlippage + 2] = amountOut;
            slippages[startingSlippage + 3] = amountOut;

            uint256[] memory withdrawalSlippages = new uint256[](4);
            withdrawalSlippages[0] = portions[0];
            withdrawalSlippages[1] = portions[1];
            withdrawalSlippages[2] = amountOut;
            withdrawalSlippages[3] = amountOut;

            emit Slippages(false, 0, abi.encode(withdrawalSlippages));
        }

        _resetAndApprove(IERC20(address(rEthToken)), address(rocketSwapRouter), amount);
        rocketSwapRouter.swapFrom(
            slippages[startingSlippage],
            slippages[startingSlippage + 1],
            slippages[startingSlippage + 2],
            slippages[startingSlippage + 3],
            amount
        );

        bought = address(this).balance;
        wrapEth(bought);
    }

    function _getSharePrice() private view returns (uint256) {
        return rEthToken.getEthValue(1 ether);
    }

    function _getProtocolRewardsInternal()
        internal
        virtual
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {}
}
