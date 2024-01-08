// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBasisAsset.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract ExtractToken is Ownable {
    IBasisAsset public immutable cash;

    constructor(IBasisAsset cash_, address owner) {
        cash = cash_;
        transferOwnership(owner);
    }

    function refundToken(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
    }

    function extract(
        address collateral,
        IUniswapV2Router02 router,
        uint256 amount
    ) external onlyOwner {
        // 2. Get the sell and buy token.
        address[] memory path = new address[](2);
        path[0] = address(cash);
        path[1] = address(collateral);

        // 4. Min the required cash.
        cash.mint(address(this), amount);

        // 5. Approve the router to use this cash.
        cash.approve(address(router), amount);

        // 6. Call the swap function on the router to swap arth and get the collateral.
        router.swapExactTokensForTokens(
            amount, // Out amount.
            0, // In amount min.
            path,
            address(this),
            block.timestamp
        );
    }
}
