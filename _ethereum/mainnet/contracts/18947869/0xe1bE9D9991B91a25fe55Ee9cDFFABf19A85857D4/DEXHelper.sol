// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./SafeTransferLib.sol";
import "./IUniswap.sol";

contract DEXHelper {
    function setupPair(
        address _router,
        address _token
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(
            IUniswapV2Router02(_router).factory()
        );
        return
            factory.createPair(
                _token,
                IUniswapV2Router02(_router).WETH()
            );
    }

    function createLiquidity(
        address _router,
        address _token,
        uint256 _value
    ) internal {
        uint256 totalBalance = SafeTransferLib.balanceOf(
            address(_token),
            address(this)
        );
        SafeTransferLib.safeApprove(_token, address(_router), totalBalance);
        IUniswapV2Router02(_router).addLiquidityETH{value: _value}(
            _token,
            totalBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}
