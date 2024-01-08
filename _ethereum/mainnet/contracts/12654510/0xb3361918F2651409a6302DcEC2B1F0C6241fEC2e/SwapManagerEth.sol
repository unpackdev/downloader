// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./OracleSimple.sol";
import "./SwapManagerBase.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SwapManagerEth is SwapManagerBase {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* solhint-enable */
    /** 
     UNISWAP: {router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f}
     SUSHISWAP: {router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F, factory: 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac}
    */
    constructor()
        SwapManagerBase(
            ["UNISWAP", "SUSHISWAP"],
            [
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
            ],
            [0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac]
        )
    {}

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountOut) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountOut = safeGetAmountsOut(_amountIn, path, _i)[path.length - 1];
            return (path, amountOut);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;
        // is one of these WETH
        if (IUniswapV2Factory(factories[_i]).getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountOut = safeGetAmountsOut(_amountIn, pathB, _i)[pathB.length - 1];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountOut) = comparePathsFixedInput(path, pathB, _amountIn, _i);
        }
    }

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountIn) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountIn = safeGetAmountsIn(_amountOut, path, _i)[0];
            return (path, amountIn);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;

        // is one of these WETH
        if (IUniswapV2Factory(factories[_i]).getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountIn = safeGetAmountsIn(_amountOut, pathB, _i)[0];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountIn) = comparePathsFixedOutput(path, pathB, _amountOut, _i);
        }
    }
}
