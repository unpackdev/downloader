// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";
import "./PendleLpOracleLib.sol";
import "./IPendleCalculations.sol";
import "./IStrategyHelper.sol";
import "./IPendle.sol";
import "./StrategyErrors.sol";
import "./ERC20Lib.sol";
import "./PendleStrategy.sol";

/**
 * @title Dollet PendleLSDStrategy contract
 * @author Dollet Team
 * @notice Contract representing a strategy for managing funds in the Pendle protocol.
 */
contract PendleLSDStrategy is PendleStrategy {
    using PendleLpOracleLib for IPMarket;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this PendleLSDStrategy contract.
     * @param _initParams Strategy initialization paramters structure.
     */
    function initialize(InitParams calldata _initParams) external initializer {
        _pendleStrategyInit(_initParams);
    }

    /**
     * @notice Performs a deposit operation.
     * @param _tokenIn Address of the token to deposit.
     * @param _amount Amount of the token to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function _deposit(address _tokenIn, uint256 _amount, bytes calldata _additionalData) internal override {
        (uint256 _minTokenOut, uint16 _slippageTolerance) = abi.decode(_additionalData, (uint256, uint16));

        uint256 _amountOut = _addLiquidityPendle(_swapUserTokenToTarget(_tokenIn, _amount, _slippageTolerance));

        if (_amountOut < _minTokenOut) revert StrategyErrors.InsufficientDepositTokenOut();
    }

    /**
     * @notice Withdraws the deposit from pendle.
     * @param _tokenOut Address of the token to withdraw in.
     * @param _wantToWithdraw The want amount to withdraw.
     * @param _additionalData Encoded data which will be used in the time of withdraw.
     */
    function _withdraw(address _tokenOut, uint256 _wantToWithdraw, bytes calldata _additionalData) internal override {
        (uint256 _minTokenOut, uint16 _slippageTolerance) = abi.decode(_additionalData, (uint256, uint16));

        uint256 _amountOut =
            _swapTargetToUserToken(_tokenOut, _removeLiquidityPendle(_wantToWithdraw), _slippageTolerance);

        if (_amountOut < _minTokenOut) revert StrategyErrors.InsufficientWithdrawalTokenOut();
    }

    /**
     * @notice Compounds rewards by claiming and converting them to the target asset. Optional param: Encoded data
     *         containing information about the compound operation.
     */
    function _compound(bytes memory) internal override {
        IMarket _pendleMarket = pendleMarket;

        _pendleMarket.redeemRewards(address(this));

        address[] memory _rewardTokens = _pendleMarket.getRewardTokens();
        uint256 _rewardTokensLength = _rewardTokens.length;
        uint256 _bal;
        IStrategyHelper _strategyHelper = strategyHelper;
        uint16 _slippageTolerance = slippageTolerance;
        address _targetAsset = targetAsset;
        address _weth = address(weth);
        uint256 _wethAmountOut;

        for (uint256 _i; _i < _rewardTokensLength;) {
            _bal = _getTokenBalance(_rewardTokens[_i]);

            if (_bal < minimumToCompound[_rewardTokens[_i]]) {
                unchecked {
                    ++_i;
                }

                continue;
            }

            ERC20Lib.safeApprove(_rewardTokens[_i], address(_strategyHelper), _bal);

            _wethAmountOut += _strategyHelper.swap(_rewardTokens[_i], _weth, _bal, _slippageTolerance, address(this));

            unchecked {
                ++_i;
            }
        }

        ERC20Lib.safeApprove(_weth, address(_strategyHelper), _wethAmountOut);

        uint256 _lsdAmountOut =
            _strategyHelper.swap(_weth, _targetAsset, _wethAmountOut, _slippageTolerance, address(this));
        uint256 _pendleLPAmountOut = _addLiquidityPendle(_lsdAmountOut);

        emit Compounded(_pendleLPAmountOut);
    }

    /**
     * @notice Swaps `_tokenIn` to `targetAsset`.
     * @param _tokenIn A token address to swap from.
     * @param _amount An amount of tokens to swap.
     * @param _slippageTolerance The user accepted slippage tolerance.
     * @return _amountOut A number of output target asset tokens.
     */
    function _swapUserTokenToTarget(
        address _tokenIn,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        private
        returns (uint256 _amountOut)
    {
        address _weth = address(weth);
        IStrategyHelper _strategyHelper = strategyHelper;
        uint256 _amountWeth = _amount;

        if (_tokenIn != _weth) {
            ERC20Lib.safeApprove(_tokenIn, address(_strategyHelper), _amount);

            _amountWeth = _strategyHelper.swap(_tokenIn, _weth, _amount, _slippageTolerance, address(this));
        }

        ERC20Lib.safeApprove(_weth, address(_strategyHelper), _amountWeth);

        return _strategyHelper.swap(_weth, targetAsset, _amountWeth, _slippageTolerance, address(this));
    }

    /**
     * @notice Swaps `targetAsset` to `_tokenOut`.
     * @param _tokenOut A token address to swap to.
     * @param _amount An amount of tokens to swap.
     * @param _slippageTolerance The user accepted slippage tolerance.
     * @return _amountOut Amount of tokens obtained.
     */
    function _swapTargetToUserToken(
        address _tokenOut,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        private
        returns (uint256 _amountOut)
    {
        address _targetAsset = targetAsset;
        IStrategyHelper _strategyHelper = strategyHelper;
        address _weth = address(weth);

        ERC20Lib.safeApprove(_targetAsset, address(_strategyHelper), _amount);

        _amountOut = _strategyHelper.swap(_targetAsset, _weth, _amount, _slippageTolerance, address(this));
        if (_tokenOut != _weth) {
            ERC20Lib.safeApprove(_weth, address(_strategyHelper), _amountOut);

            _amountOut = _strategyHelper.swap(_weth, _tokenOut, _amountOut, _slippageTolerance, address(this));
        }
    }
}
