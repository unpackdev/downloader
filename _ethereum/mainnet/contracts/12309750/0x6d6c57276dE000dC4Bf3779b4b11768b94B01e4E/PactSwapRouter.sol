// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./UniswapV2Router02.sol";
import "./IPactSwapRouter.sol";
import "./IPactSwapFactory.sol";
import "./IWETH.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

contract PactSwapRouter is IPactSwapRouter, UniswapV2Router02 {

    constructor(address _factory, address _WETH) UniswapV2Router02(_factory, _WETH) public {}

    modifier onlyGovernance() {
        require(IPactSwapFactory(factory).governance() == msg.sender, "Governance: caller is not the governance");
        _;
    }

    function removeIncentivesPoolLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenAMin,
        uint amountTokenBMin,
        uint deadline
    ) public virtual override ensure(deadline) onlyGovernance() returns (uint amountTokenA, uint amountTokenB) {
        IPactSwapFactory factory_ = IPactSwapFactory(factory);
        require(factory_.incentivesPool() != address(0), "removeIncentivesPoolLiquidity: incentivesPool is zero address");
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        (amountTokenA, amountTokenB) = removeLiquidity(
            tokenA,
            tokenB,
            IERC20(pair).balanceOf(factory_.incentivesPool()),
            amountTokenAMin,
            amountTokenBMin,
            address(this),
            deadline
        );

        withdrawTo(tokenA, factory_.incentivesPool(), amountTokenA);
        withdrawTo(tokenB, factory_.incentivesPool(), amountTokenB);
    }

    function withdrawTo(address token, address account, uint amountToken) internal {
        if (token == WETH) {
            IWETH(WETH).withdraw(amountToken);
            TransferHelper.safeTransferETH(account, amountToken);
        } else {
            TransferHelper.safeTransfer(token, account, amountToken);
        }
    }
}