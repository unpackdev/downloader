// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity ^0.8.0;

import "./ISwapRouter.sol";
import "./RevenueShare.sol";
import "./AllowanceChecker.sol";

contract RevenueShareVault is RevenueShare, AllowanceChecker {

    ISwapRouter public swapRouter;
    IERC20 public revenueToken;

    constructor(
        IERC20 _underlying,
        IERC20 _revenueToken,
        string memory _name,
        string memory _symbol,
        ISwapRouter _swapRouter
    ) RevenueShare(IERC20(_underlying), _name, _symbol) {
        swapRouter = _swapRouter;
        revenueToken = _revenueToken;
    }

    function compound() external {

        approveIfNeeded(address(revenueToken), address(swapRouter));

        address[] memory path = new address[](2);
        path[0] = address(revenueToken);
        path[1] = swapRouter.weth();

        swapRouter.compound(path, revenueToken.balanceOf(address(this)));
    }

    function sellWeth(uint56 _outAmount) external {
        approveIfNeeded(swapRouter.weth(), address(swapRouter));

        address[] memory path = new address[](2);
        path[0] = swapRouter.weth();
        path[1] = address(revenueToken);

        swapRouter.swapExactTokensForTokens(
            path,
            IERC20(swapRouter.weth()).balanceOf(address(this)),
            _outAmount
        );
    }

}
