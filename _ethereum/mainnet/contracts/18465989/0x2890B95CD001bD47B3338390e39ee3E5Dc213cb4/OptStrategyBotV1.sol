// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./OptStrategy.sol";
import "./VaultFacet.sol";

contract OptStrategyBotV1 {
    error CallFailed(address contract_, bytes data, uint256 actionIndex);

    using SafeERC20 for IERC20;

    address public immutable owner;

    constructor(address owner_) {
        owner = owner_;
    }

    struct Data {
        OptStrategy strategy;
        bytes[] actions;
    }

    function claim(address[] memory tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) IERC20(tokens[i]).safeTransfer(owner, balance);
        }
    }

    function _transferAllTokens(address[] memory tokens, address vault) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(vault);
            if (balance > 0) IERC20(tokens[i]).safeTransferFrom(vault, address(this), balance);
        }
    }

    function _processSwapIntoYield(Data memory data, VaultFacet vault, address yieldToken) private {
        address[] memory tokens = vault.tokens();
        _transferAllTokens(tokens, address(vault));
        // first token is uniV3Token
        UniV3Token token = UniV3Token(tokens[0]);
        token.withdraw(IERC20(address(token)).balanceOf(address(this)), new uint256[](2));

        // approves && swaps tokens into yield protocol
        for (uint256 i = 0; i < data.actions.length; i++) {
            if (data.actions[i].length == 0) break;
            (address c, bytes memory action) = abi.decode(data.actions[i], (address, bytes));
            (bool success, ) = c.call(action);
            if (!success) revert CallFailed(c, action, i);
        }

        // transfer token back
        IERC20(yieldToken).safeTransfer(address(vault), IERC20(yieldToken).balanceOf(address(this)));
    }

    function _processSwapIntoUniswap(Data memory data, VaultFacet vault) private {
        address[] memory tokens = vault.tokens();
        _transferAllTokens(tokens, address(vault));
        // first token is uni token
        UniV3Token uniV3Token = UniV3Token(tokens[0]);

        // approves && swaps tokens into yield protocol
        for (uint256 i = 0; i < data.actions.length; i++) {
            if (data.actions[i].length == 0) break;
            (address c, bytes memory action) = abi.decode(data.actions[i], (address, bytes));
            (bool success, ) = c.call(action);
            if (!success) revert CallFailed(c, action, i);
        }

        address token0 = uniV3Token.token0();
        address token1 = uniV3Token.token1();

        IERC20(token0).safeApprove(address(uniV3Token), type(uint256).max);
        IERC20(token1).safeApprove(address(uniV3Token), type(uint256).max);

        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAmounts[0] = IERC20(token0).balanceOf(address(this));
        tokenAmounts[1] = IERC20(token1).balanceOf(address(this));

        uniV3Token.deposit(tokenAmounts, 0);

        IERC20(token0).safeApprove(address(uniV3Token), 0);
        IERC20(token1).safeApprove(address(uniV3Token), 0);

        IERC20(address(uniV3Token)).safeTransfer(address(vault), uniV3Token.balanceOf(address(this)));
    }

    function rebalance(Data memory data) external {
        VaultFacet vault = VaultFacet(msg.sender);
        OptStrategy strategy = data.strategy;
        OptStrategy.ImmutableParams memory immutableParams = strategy.getImmutableParams();
        OptStrategy.State currentState = OptStrategy.State(strategy.getCurrentState());
        int24 tick = strategy.getAverageTick();

        if (currentState == OptStrategy.State.UNISWAP) {
            if (tick < immutableParams.lowerTick) {
                _processSwapIntoYield(data, vault, immutableParams.yieldToken0);
            } else {
                _processSwapIntoYield(data, vault, immutableParams.yieldToken1);
            }
        } else if (currentState == OptStrategy.State.YIELD_0) {
            _processSwapIntoUniswap(data, vault);
        } else {
            _processSwapIntoUniswap(data, vault);
        }
    }
}
