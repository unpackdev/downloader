// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

contract BUYBACK is Ownable {
    receive() external payable {}

    fallback() external payable {}

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 public router;
    IERC20 public token;
    IUniswapV2Pair public pair;

    function setRouterAndToken(address newRouterAddress, address newTokenAddress) public onlyOwner {

        router = IUniswapV2Router02(newRouterAddress);

        pair = IUniswapV2Pair(IUniswapV2Factory(router.factory()).getPair(newTokenAddress, router.WETH()));

        token = IERC20(newTokenAddress);

        require(address(pair) != address(0), 'Error token or router addresses');
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

    function buyAndBurn() external onlyOwner {
        uint256 balance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: balance}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(deadAddress, tokenAmount);
    }
}
