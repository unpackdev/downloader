// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ReentrancyGuard.sol";
import "./IThorchainRouter.sol";
import "./IUniswapV3.sol";
import "./IWETH.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract RangoThorchainOutputAggUniV3 is ReentrancyGuard {
    IWETH public nativeWrappedToken;
    IUniswapV3 public dexRouter;
    uint24 public v3PoolFee;

    constructor(address _nativeWrappedAddress, address _dexRouter, uint24 _v3PoolFee) {
        nativeWrappedToken = IWETH(_nativeWrappedAddress);
        dexRouter = IUniswapV3(_dexRouter);
        v3PoolFee = _v3PoolFee;
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

    //############################## OUT ##############################
    function swapOut(address token, address to, uint256 amountOutMin) public payable nonReentrant {
        nativeWrappedToken.deposit{value : msg.value}();
        SafeERC20.safeIncreaseAllowance(IERC20(address(nativeWrappedToken)), address(dexRouter), msg.value);
        dexRouter.exactInputSingle(
            IUniswapV3.ExactInputSingleParams(
            {
            tokenIn : address(nativeWrappedToken),
            tokenOut : token,
            fee : v3PoolFee,
            recipient : to,
            deadline : type(uint).max,
            amountIn : msg.value,
            amountOutMinimum : amountOutMin,
            sqrtPriceLimitX96 : 0
            })
        );
    }

}