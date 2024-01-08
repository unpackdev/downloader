// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ITOS.sol";
import "./iPowerTON.sol";
import "./ISwapRouter.sol";

contract PowerTONSwapper is iPowerTON {
    address public override wton;
    ITOS public tos;
    ISwapRouter public uniswapRouter;

    event Swapped(
        uint256 amount
    );

    constructor(
        address _wton,
        address _tos,
        address _uniswapRouter
    )
    {
        wton = _wton;
        tos = ITOS(_tos);
        uniswapRouter = ISwapRouter(_uniswapRouter);
    }

    function approveToUniswap() external {
        IERC20(wton).approve(
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
                tokenIn: wton,
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
        return IERC20(wton).balanceOf(address(this));
    }

    // PowerTON functions

    function seigManager() external view returns (address) {
        return address(0);
    }

    function currentRound() external view returns (uint256) {
        return 0;
    }

    function roundDuration() external view returns (uint256) {
        return 0;
    }

    function totalDeposits() external view returns (uint256) {
        return 0;
    }

    function winnerOf(uint256 round) external view returns (address) {
        return address(0);
    }

    function powerOf(address account) external view returns (uint256) {
        return 0;
    }

    function init() external {
    }

    function start() external {
    }

    function endRound() external {
    }

    function onDeposit(address layer2, address account, uint256 amount) external {
    }

    function onWithdraw(address layer2, address account, uint256 amount) external {
    }
}
