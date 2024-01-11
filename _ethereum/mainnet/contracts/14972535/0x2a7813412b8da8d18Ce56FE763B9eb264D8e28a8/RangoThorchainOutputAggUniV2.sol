// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ReentrancyGuard.sol";
import "./IThorchainRouter.sol";
import "./IUniswapV2.sol";


contract RangoThorchainOutputAggUniV2 is ReentrancyGuard {
    address public nativeWrappedAddress;
    IUniswapV2 public dexRouter;

    constructor(address _nativeWrappedAddress, address _dexRouter) {
        nativeWrappedAddress = _nativeWrappedAddress;
        dexRouter = IUniswapV2(_dexRouter);
    }

    function swapIn(
        address tcRouter,
        address tcVault,
        string calldata tcMemo,
        address token,
        uint amount,
        uint amountOutMin,
        uint deadline
    ) public nonReentrant {
        revert("this contract only supports swapOut");
    }

    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        address[] memory path = new address[](2);
        path[0] = nativeWrappedAddress;
        path[1] = token;
        dexRouter.swapExactETHForTokens{value : msg.value}(amountOutMin, path, to, type(uint).max);
    }

}