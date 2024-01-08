// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ITOS.sol";
import "./ISwapRouter.sol";

contract PowerTONSwapper {
    IERC20 wton;
    ITOS tos;
    ISwapRouter uniswapRouter;

    event Swapped(
        uint256 amount
    );

    constructor(
        address _wton,
        address _tos,
        address _uniswapRouter
    )
    {
        wton = IERC20(_wton);
        tos = ITOS(_tos);
        uniswapRouter = ISwapRouter(_uniswapRouter);
    }

    function approveToUniswap() external {
        wton.approve(
            address(uniswapRouter),
            type(uint256).max
        );
    }

    function swap(
        uint24 _fee,
        uint256 _deadline,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
    )
        external
    {
        uint256 wtonBalance = getWTONBalance();

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(wton),
                tokenOut: address(tos),
                fee: _fee,
                recipient: address(this),
                deadline: block.timestamp + _deadline,
                amountIn: wtonBalance,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            });
        ISwapRouter(uniswapRouter).exactInputSingle(params);

        uint256 burnAmount = tos.balanceOf(address(this));
        tos.burn(address(this), burnAmount);

        emit Swapped(burnAmount);
    }

    function getWTONBalance() public view returns(uint256) {
        return wton.balanceOf(address(this));
    }
}
