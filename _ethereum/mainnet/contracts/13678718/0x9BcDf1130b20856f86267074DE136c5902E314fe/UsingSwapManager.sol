// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./Governed.sol";
import "./ISwapManager.sol";

abstract contract UsingSwapManager is Governed {
    using SafeERC20 for IERC20;

    address weth; // Native token
    ISwapManager public swapManager;
    uint256 public oraclePeriod = 3600; // 1h;
    uint256 public oracleRouterIdx = 0; // Uniswap V2;
    uint256 public swapSlippage = 1000; // 10%

    event UpdatedSwapManager(address indexed oldSwapManager, address indexed newSwapManager);
    event UpdatedSwapSlippage(uint256 oldSwapSlippage, uint256 newSwapSlippage);
    event UpdatedOracleConfig(uint256 oldPeriod, uint256 newPeriod, uint256 oldRouterIdx, uint256 newRouterIdx);

    constructor(address _weth, ISwapManager _swapManager) {
        require(address(_weth) != address(0), "weth-is-null");
        require(address(_swapManager) != address(0), "swap-manager-is-null");

        weth = _weth;
        swapManager = _swapManager;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyGovernor {
        require(_swapManager != address(0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    /**
     * @notice Update swap slippage value
     * @param _newSwapSlippage new swap slippage
     */
    function updateSwapSlippage(uint256 _newSwapSlippage) external onlyGovernor {
        require(_newSwapSlippage <= 10000, "invalid-slippage-value");
        emit UpdatedSwapSlippage(swapSlippage, _newSwapSlippage);
        swapSlippage = _newSwapSlippage;
    }

    function updateOracleConfig(uint256 _newPeriod, uint256 _newRouterIdx) external onlyGovernor {
        require(_newRouterIdx < swapManager.N_DEX(), "invalid-router-index");
        if (_newPeriod == 0) _newPeriod = oraclePeriod;
        require(_newPeriod > 59, "invalid-oracle-period");
        emit UpdatedOracleConfig(oraclePeriod, _newPeriod, oracleRouterIdx, _newRouterIdx);
        oraclePeriod = _newPeriod;
        oracleRouterIdx = _newRouterIdx;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Safe swap via Uniswap / Sushiswap (better rate of the two)
     * @dev There are many scenarios when token swap via Uniswap can fail, so this
     * method will wrap Uniswap call in a 'try catch' to make it fail safe.
     * however, this method will throw minAmountOut is not met
     * @param _tokenIn address of from token
     * @param _tokenOut address of to token
     * @param _amountIn Amount to be swapped
     * @param _minAmountOut minimum amount out
     */
    function _safeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to
    ) internal {
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(_tokenIn, _tokenOut, _amountIn);
        if (_minAmountOut == 0) _minAmountOut = 1;
        if (amountOut != 0) {
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(_amountIn, _minAmountOut, path, _to, block.timestamp);
        }
    }

    function _calcAmtOutAfterSlippage(uint256 _amount, uint256 _slippage) internal pure returns (uint256) {
        return (_amount * (10000 - _slippage)) / (10000);
    }

    function _getOracleRate(address[] memory path, uint256 _amountIn) internal returns (uint256 amountOut) {
        require(path.length > 1, "invalid-oracle-path");
        amountOut = _amountIn;
        bool isValid;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (amountOut, isValid) = _consultOracle(path[i], path[i + 1], amountOut);
            require(isValid, "invalid-oracle-rate");
        }
    }

    function _simpleOraclePath(address _from, address _to) internal view returns (address[] memory path) {
        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        // from, to, amountIn, period, router
        (uint256 rate, uint256 lastUpdate, ) = swapManager.consult(_from, _to, _amt, oraclePeriod, oracleRouterIdx);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - oraclePeriod)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    function _doInfinityApprovalIfNeeded(IERC20 _asset, uint256 _amountToSwap) internal {
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            if (IERC20(_asset).allowance(address(this), address(swapManager.ROUTERS(i))) < _amountToSwap) {
                IERC20(_asset).safeApprove(address(swapManager.ROUTERS(i)), type(uint256).max);
            }
        }
    }
}
