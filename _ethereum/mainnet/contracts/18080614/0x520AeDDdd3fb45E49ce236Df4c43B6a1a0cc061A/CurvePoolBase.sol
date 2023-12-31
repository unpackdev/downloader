// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ICurvePool.sol";
import "./uint16a16Lib.sol";
import "./Strategy.sol";
import "./StrategyManualYieldVerifier.sol";

// multiple assets
abstract contract CurvePoolBase is StrategyManualYieldVerifier, Strategy {
    using SafeERC20 for IERC20;
    using uint16a16Lib for uint16a16;

    ISwapper public immutable swapper;

    IERC20 public lpToken;
    uint16a16 public assetMapping;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        uint256 assetGroupId_,
        ISwapper swapper_
    ) Strategy(assetGroupRegistry_, accessControl_, assetGroupId_) {
        swapper = swapper_;
    }

    function __CurvePoolBase_init(
        string memory strategyName_,
        uint256 assetGroupId_,
        IERC20 lpToken_,
        uint16a16 assetMapping_,
        int128 positiveYieldLimit_,
        int128 negativeYieldLimit_
    ) internal onlyInitializing {
        __Strategy_init(strategyName_, assetGroupId_);

        if (address(lpToken_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        address[] memory tokens = _assetGroupRegistry.listAssetGroup(assetGroupId());

        lpToken = lpToken_;

        if (tokens.length != _ncoins()) {
            revert InvalidAssetGroup(assetGroupId());
        }
        for (uint256 i; i < _ncoins(); ++i) {
            if (tokens[i] != _coins(assetMapping_.get(i))) {
                revert InvalidAssetGroup(assetGroupId());
            }
        }

        assetMapping = assetMapping_;

        _setPositiveYieldLimit(positiveYieldLimit_);
        _setNegativeYieldLimit(negativeYieldLimit_);
    }

    function _compound(address[] calldata tokens, SwapInfo[] calldata compoundSwapInfo, uint256[] calldata slippages)
        internal
        virtual
        override
        returns (int256 compoundYield)
    {
        if (compoundSwapInfo.length == 0) {
            return compoundYield;
        }

        (address[] memory rewardTokens,) = _getProtocolRewardsInternal();

        uint256[] memory swapped = swapper.swap(rewardTokens, compoundSwapInfo, tokens, address(this));

        uint256 lpTokensBefore = _lpTokenBalance();
        _depositToCurveCompound(tokens, swapped, slippages);
        uint256 lpTokensMinted = _lpTokenBalance() - lpTokensBefore;

        compoundYield = int256(YIELD_FULL_PERCENT * lpTokensMinted / lpTokensBefore);
    }

    function _getYieldPercentage(int256 manualYield) internal view override returns (int256) {
        _verifyManualYieldPercentage(manualYield);
        return manualYield;
    }

    function _swapAssets(address[] memory tokens, uint256[] memory toSwap, SwapInfo[] calldata swapInfo)
        internal
        virtual
        override
    {}

    function _coins(uint256 index) internal view virtual returns (address);

    function _balances(uint256 index) internal view virtual returns (uint256);

    function _lpTokenBalance() internal view virtual returns (uint256);

    function _handleDeposit() internal virtual;

    function _handleWithdrawal(uint256 lpTokens) internal virtual;

    function _depositToCurveCompound(address[] memory tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        virtual;

    function _getRewards() internal virtual returns (address[] memory);

    function _ncoins() internal pure virtual returns (uint256);

    function _getProtocolRewardsInternal() internal virtual override returns (address[] memory, uint256[] memory) {
        address[] memory rewardTokens = _getRewards();
        uint256[] memory balances = new uint256[](rewardTokens.length);

        for (uint256 i; i < rewardTokens.length; ++i) {
            uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(rewardTokens[i]).safeTransfer(address(swapper), balance);

                balances[i] = balance;
            }
        }

        return (rewardTokens, balances);
    }
}
