// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";

import "./IPriceFeed.sol";

import "./AbstractDependant.sol";

contract PriceFeed is IPriceFeed, AbstractDependant {
    IUniswapV2Router02 public uniswapRouter;

    address public wethToken;
    address public bmiToken;
    address public daiToken;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        uniswapRouter = IUniswapV2Router02(_contractsRegistry.getUniswapRouterContract());
        wethToken = _contractsRegistry.getWETHContract();
        bmiToken = _contractsRegistry.getBMIContract();
        daiToken = _contractsRegistry.getDAIContract();
    }

    function howManyBMIsInDAI(uint256 daiAmount) external view override returns (uint256) {
        if (daiAmount == 0) {
            return 0;
        }

        address[] memory pairs = new address[](3);
        pairs[0] = daiToken;
        pairs[1] = wethToken;
        pairs[2] = bmiToken;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(daiAmount, pairs);

        return amounts[amounts.length - 1];
    }

    function howManyDAIsInBMI(uint256 bmiAmount) external view override returns (uint256) {
        if (bmiAmount == 0) {
            return 0;
        }

        address[] memory pairs = new address[](3);
        pairs[0] = bmiToken;
        pairs[1] = wethToken;
        pairs[2] = daiToken;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(bmiAmount, pairs);

        return amounts[amounts.length - 1];
    }
}
