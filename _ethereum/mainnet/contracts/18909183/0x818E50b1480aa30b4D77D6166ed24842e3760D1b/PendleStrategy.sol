// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";
import "./IPendleCalculations.sol";
import "./IPendle.sol";
import "./IPendleStrategy.sol";
import "./AddressUtils.sol";
import "./ERC20Lib.sol";
import "./Strategy.sol";

/**
 * @title Dollet PendleStrategy contract
 * @author Dollet Team
 * @notice Abstract contract representing a strategy for managing funds in the Pendle protocol.
 */
abstract contract PendleStrategy is Strategy, IPendleStrategy {
    using AddressUtils for address;

    // Addresses of Pendle protocol contracts
    IRouter public pendleRouter;
    IMarket public pendleMarket;

    // Address of the target asset in the strategy
    address public targetAsset;

    // Time-weighted average price (TWAP) period for oracle calculations
    uint32 public twapPeriod;

    /// @inheritdoc IPendleStrategy
    function setTwapPeriod(uint32 _newTwapPeriod) external {
        _onlyAdmin();

        twapPeriod = _newTwapPeriod;
    }

    /// @inheritdoc IPendleStrategy
    function balance() public view virtual override(Strategy, IPendleStrategy) returns (uint256) {
        return _getTokenBalance(want);
    }

    /// @inheritdoc IPendleStrategy
    function getPendingToCompound(bytes calldata _rewardData)
        public
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        )
    {
        return IPendleCalculations(address(calculations)).getPendingToCompound(_rewardData);
    }

    /**
     * @notice Initializes this Pendle Strategy contract.
     * @param _initParams Strategy initialization paramters structure.
     */
    function _pendleStrategyInit(InitParams calldata _initParams) internal onlyInitializing {
        AddressUtils.onlyContract(_initParams.pendleRouter);
        AddressUtils.onlyContract(_initParams.pendleMarket);

        pendleRouter = IRouter(_initParams.pendleRouter);
        pendleMarket = IMarket(_initParams.pendleMarket);

        _strategyInitUnchained(
            _initParams.adminStructure,
            _initParams.strategyHelper,
            _initParams.feeManager,
            _initParams.weth,
            _initParams.want,
            _initParams.calculations,
            _initParams.tokensToCompound,
            _initParams.minimumsToCompound
        );

        (address _sy,,) = pendleMarket.readTokens();
        (, targetAsset,) = ISyToken(_sy).assetInfo();
        twapPeriod = _initParams.twapPeriod;
    }

    /**
     * @notice Interacts with Pendle to make a deposit directly in the underlying token.
     * @param _amountIn An amount of `targetAsset` tokens to add as liquidity to the Pendle protocol.
     * @return _amountOut The obtained want
     */
    function _addLiquidityPendle(uint256 _amountIn) internal returns (uint256 _amountOut) {
        if (_amountIn == 0) return 0;

        IRouter _pendleRouter = pendleRouter;
        address _targetAsset = targetAsset;

        ERC20Lib.safeApprove(_targetAsset, address(_pendleRouter), _amountIn);

        (_amountOut,) = _pendleRouter.addLiquiditySingleToken(
            address(this),
            address(pendleMarket),
            0,
            IMarket.ApproxParams({
                guessMin: 0,
                guessMax: type(uint256).max,
                guessOffchain: 0,
                maxIteration: 256,
                eps: 1e14
            }),
            IRouter.TokenInput({
                tokenIn: _targetAsset,
                netTokenIn: _amountIn,
                tokenMintSy: _targetAsset,
                bulk: address(0),
                pendleSwap: address(0),
                swapData: (new ISwapAggregator.SwapData[](1))[0]
            })
        );
    }

    /**
     * @notice Interacts with Pendle to make a withdrawal.
     * @param _amountWantToRemove The amount of want (LP) tokens to withdraw.
     * @return _amountOut The minimum expected token amount.
     */
    function _removeLiquidityPendle(uint256 _amountWantToRemove) internal returns (uint256 _amountOut) {
        IMarket _pendleMarket = pendleMarket;
        IRouter _pendleRouter = pendleRouter;
        address _targetAsset = targetAsset;
        IRouter.TokenOutput memory _tokenOutput = IRouter.TokenOutput({
            tokenOut: _targetAsset,
            minTokenOut: 0,
            tokenRedeemSy: _targetAsset,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: (new ISwapAggregator.SwapData[](1))[0]
        });

        ERC20Lib.safeApprove(address(_pendleMarket), address(_pendleRouter), _amountWantToRemove);

        (_amountOut,) = _pendleRouter.removeLiquiditySingleToken(
            address(this), address(_pendleMarket), _amountWantToRemove, _tokenOutput
        );
    }

    uint256[50] private __gap;
}
