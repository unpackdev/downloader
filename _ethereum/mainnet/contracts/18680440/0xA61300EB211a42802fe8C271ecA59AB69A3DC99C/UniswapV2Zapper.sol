// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./SafeTransferLib.sol";

import "./IUniswapV2Router.sol";

contract UniswapV2Zapper {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    address public immutable WETH;
    address public immutable UniRouter;

    constructor(address _WETH, address _UniRouter) {
        WETH = _WETH;
        UniRouter = _UniRouter;

        ERC20(WETH).safeApprove(UniRouter, type(uint256).max);
    }

    function zapEthToHalfEthLP(address lpToken, address[] memory route)
        external
        payable
        checkApprovals(lpToken)
        returns (uint256 tokensReturned)
    {

        uint[] memory amounts = IUniswapV2Router(UniRouter).swapExactETHForTokens{value: msg.value / 2}(
            0,
            route,
            address(this),
            block.timestamp + 60 minutes
        );

        address inToken = IUniswapV2Pool(lpToken).token0() == WETH ? IUniswapV2Pool(lpToken).token1() : IUniswapV2Pool(lpToken).token0();

        //Determine the other half of the LP
        (,, uint256 tokens) = IUniswapV2Router(UniRouter).addLiquidityETH{value: msg.value / 2}(
            inToken, //inToken
            amounts[amounts.length - 1], //amountTokenDesired
            0, //amountTokenMin
            0, //amountETHMin
            msg.sender, //Zap them back to the sender
            block.timestamp + 60
        );

        //Send Any unused ETH back to the sender
        msg.sender.safeTransferETH(address(this).balance);

        if (ERC20(inToken).balanceOf(address(this)) != 0) {
            ERC20(inToken).safeTransfer(msg.sender, ERC20(inToken).balanceOf(address(this)));
        }

        return tokens;
    }

    //Receive unused ETH from the router when minting LPs
    fallback() external payable {}
    receive() external payable {}

    modifier checkApprovals(address lpToken) {
        address token0 = IUniswapV2Pool(lpToken).token0();
        address token1 = IUniswapV2Pool(lpToken).token1();

        if (ERC20(token0).allowance(address(this), UniRouter) != type(uint).max) {
            ERC20(token0).safeApprove(UniRouter, type(uint256).max);
        }

        if (ERC20(token1).allowance(address(this), UniRouter) != type(uint).max) {
            ERC20(token1).safeApprove(UniRouter, type(uint256).max);
        }

        _;
    }
}
