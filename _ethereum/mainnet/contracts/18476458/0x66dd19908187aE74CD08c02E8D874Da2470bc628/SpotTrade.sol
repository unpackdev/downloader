// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Commands.sol";
import "./Errors.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniversalRouter.sol";
import "./IPermit2.sol";
import "./IUniswapV2Router02.sol";
import "./Commands.sol";
import "./BytesLib.sol";
import "./IOperator.sol";

library SpotTrade {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    function uni(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline,
        bytes memory addresses
    ) external returns (uint96) {
        (address receiver, address operator) = abi.decode(addresses, (address, address));
        address universalRouter = IOperator(operator).getAddress("UNIVERSALROUTER");
        address permit2 = IOperator(operator).getAddress("PERMIT2");
        _check(tokenIn, tokenOut, amountIn, commands, inputs, receiver);

        IERC20(tokenIn).approve(address(permit2), amountIn);
        IPermit2(permit2).approve(tokenIn, address(universalRouter), uint160(amountIn), type(uint48).max);

        uint96 balanceBeforeSwap = uint96(IERC20(tokenOut).balanceOf(receiver));
        if (deadline > 0) IUniversalRouter(universalRouter).execute(commands, inputs, deadline);
        else IUniversalRouter(universalRouter).execute(commands, inputs);
        uint96 balanceAfterSwap = uint96(IERC20(tokenOut).balanceOf(receiver));

        return balanceAfterSwap - balanceBeforeSwap;
    }

    function _check(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        address receiver
    ) internal pure {
        uint256 amount;
        for (uint256 i = 0; i < commands.length;) {
            bytes calldata input = inputs[i];
            // the address of the receiver should be spot when opening and trade when closing
            if (address(bytes20(input[12:32])) != receiver) revert Errors.InputMismatch();
            // since the route can be through v2 and v3, adding the swap amount for each input should be equal to the total swap amount
            amount += uint256(bytes32(input[32:64]));

            if (commands[i] == bytes1(uint8(UniCommands.V2_SWAP_EXACT_IN))) {
                address[] calldata path = input.toAddressArray(3);
                // the first address of the path should be tokenIn
                if (path[0] != tokenIn) revert Errors.InputMismatch();
                // last address of the path should be the tokenOut
                if (path[path.length - 1] != tokenOut) revert Errors.InputMismatch();
            } else if (commands[i] == bytes1(uint8(UniCommands.V3_SWAP_EXACT_IN))) {
                bytes calldata path = input.toBytes(3);
                // the first address of the path should be tokenIn
                if (address(bytes20(path[:20])) != tokenIn) revert Errors.InputMismatch();
                // last address of the path should be the tokenOut
                if (address(bytes20(path[path.length - 20:])) != tokenOut) revert Errors.InputMismatch();
            } else {
                // if its not v2 or v3, then revert
                revert Errors.CommandMisMatch();
            }
            unchecked {
                ++i;
            }
        }
        if (amount != uint256(amountIn)) revert Errors.InputMismatch();
    }

    function sushi(
        address tokenIn,
        address tokenOut,
        uint96 amountIn,
        uint256 amountOutMin,
        address receiver,
        address operator
    ) external returns (uint96) {
        address router = IOperator(operator).getAddress("SUSHIROUTER");
        IERC20(tokenIn).approve(router, amountIn);
        address[] memory tokenPath;
        address wrappedToken = IOperator(operator).getAddress("WRAPPEDTOKEN");

        if (tokenIn == wrappedToken || tokenOut == wrappedToken) {
            tokenPath = new address[](2);
            tokenPath[0] = tokenIn;
            tokenPath[1] = tokenOut;
        } else {
            tokenPath = new address[](3);
            tokenPath[0] = tokenIn;
            tokenPath[1] = wrappedToken;
            tokenPath[2] = tokenOut;
        }

        uint96 balanceBeforeSwap = uint96(IERC20(tokenOut).balanceOf(receiver));
        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn, amountOutMin, tokenPath, receiver, block.timestamp
        );
        uint96 balanceAfterSwap = uint96(IERC20(tokenOut).balanceOf(receiver));
        return balanceAfterSwap - balanceBeforeSwap;
    }

    function oneInch(address tokenIn, address tokenOut, address receiver, bytes memory exchangeData, address operator)
        external
        returns (uint96)
    {
        if (exchangeData.length == 0) revert Errors.ExchangeDataMismatch();
        address router = IOperator(operator).getAddress("ONEINCHROUTER");
        address vault = IOperator(operator).getAddress("VAULT");
        uint256 tokenInBalanceBefore = IERC20(tokenIn).balanceOf(vault);
        uint256 tokenOutBalanceBefore = IERC20(tokenOut).balanceOf(receiver);
        IERC20(tokenIn).safeApprove(router, type(uint256).max);
        (bool success,) = router.call(exchangeData);
        if (success) {
            IERC20(tokenIn).safeApprove(router, 0);
            uint256 tokenInBalanceAfter = IERC20(tokenIn).balanceOf(vault);
            uint256 tokenOutBalanceAfter = IERC20(tokenOut).balanceOf(receiver);
            if (tokenInBalanceAfter >= tokenInBalanceBefore) revert Errors.BalanceLessThanAmount();
            if (tokenOutBalanceAfter <= tokenOutBalanceBefore) revert Errors.BalanceLessThanAmount();
            return uint96(tokenOutBalanceAfter - tokenOutBalanceBefore);
        } else {
            revert Errors.SwapFailed();
        }
    }
}
