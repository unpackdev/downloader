// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ILiquidityDex.sol";
import "./IBancorV3Network.sol";
import "./Weth9.sol";

contract BancorV3Dex is ILiquidityDex, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    receive() external payable {}

    address public network;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public bancorEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _network) public {
        network = _network;
    }

    function changeNetwork(address _network) public onlyOwner {
        network = _network;
    }

    function doSwap(
        uint256 amountIn,
        uint256 minAmountOut,
        address spender,
        address target,
        address[] memory path
    ) public override returns (uint256) {
        require(path.length == 2, "Only provide initial and final token");
        address buyToken = path[1];
        address sellToken = path[0];
        address finalTarget = target;

        IERC20(sellToken).safeTransferFrom(spender, address(this), amountIn);

        if (sellToken == weth) {
          WETH9(weth).withdraw(amountIn);
          sellToken = bancorEth;
        } else {
          IERC20(sellToken).safeIncreaseAllowance(address(network), amountIn);
        }

        if (buyToken == weth) {
          buyToken = bancorEth;
          // we will be receiving eth here, and wrap it back to WETH
          target = address(this);
        }

        uint256 outTokenReturned = IBancorV3Network(network).tradeBySourceAmount{value: sellToken == bancorEth ? amountIn : 0}(
            Token(sellToken),
            Token(buyToken),
            amountIn,
            minAmountOut,
            block.timestamp,
            target
        );

        // If buyToken is bancorEth, then this contract has received ETH after the swap.
        // ETH should be wrapped back to WETH
        if(buyToken == bancorEth) {
          uint256 ethBalance = address(this).balance;
          WETH9(weth).deposit{value: ethBalance}();
          outTokenReturned = IERC20(weth).balanceOf(address(this));
          IERC20(weth).safeTransfer(finalTarget, outTokenReturned);
        }

        return outTokenReturned;
    }
}
