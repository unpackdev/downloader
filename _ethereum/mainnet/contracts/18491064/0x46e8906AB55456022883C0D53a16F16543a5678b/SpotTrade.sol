// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Test.sol";
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
import "./IStvAccount.sol";

contract SpotTrade {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    address public operator;

    constructor(address _operator) {
        operator = _operator;
    }

    modifier onlyVault() {
        address vault = IOperator(operator).getAddress("VAULT");
        if (msg.sender != vault) revert Errors.NoAccess();
        _;
    }

    function uni(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline,
        bytes memory addresses
    ) external onlyVault returns (uint256) {
        address receiver = abi.decode(addresses, (address));
        address universalRouter = IOperator(operator).getAddress("UNIVERSALROUTER");
        _check(tokenIn, tokenOut, amountIn, commands, inputs, receiver);

        _approveUni(receiver, tokenIn, universalRouter, uint160(amountIn));
        uint256 balanceBeforeSwap = IERC20(tokenOut).balanceOf(receiver);
        if (deadline > 0) {
            bytes memory swapTxData =
                abi.encodeWithSignature("execute(bytes,bytes[],uint256)", commands, inputs, deadline);
            IStvAccount(receiver).execute(universalRouter, swapTxData, 0);
        } else {
            bytes memory swapTxData = abi.encodeWithSignature("execute(bytes,bytes[])", commands, inputs);
            IStvAccount(receiver).execute(universalRouter, swapTxData, 0);
        }
        uint256 balanceAfterSwap = IERC20(tokenOut).balanceOf(receiver);

        return balanceAfterSwap - balanceBeforeSwap;
    }

    function _approveUni(address receiver, address tokenIn, address universalRouter, uint160 amountIn) internal {
        address permit2 = IOperator(operator).getAddress("PERMIT2");
        bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", permit2, type(uint48).max);
        IStvAccount(receiver).execute(tokenIn, approvalData, 0);
        approvalData = abi.encodeWithSignature(
            "approve(address,address,uint160,uint48)", tokenIn, universalRouter, uint160(amountIn), type(uint48).max
        );
        IStvAccount(receiver).execute(permit2, approvalData, 0);
    }

    function _check(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
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

    function sushi(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address receiver)
        external
        onlyVault
        returns (uint256)
    {
        address router = IOperator(operator).getAddress("SUSHIROUTER");
        bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", router, amountIn);
        IStvAccount(receiver).execute(tokenIn, approvalData, 0);
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

        uint256 balanceBeforeSwap = IERC20(tokenOut).balanceOf(receiver);
        bytes memory swapTxData = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amountIn,
            amountOutMin,
            tokenPath,
            receiver,
            block.timestamp
        );
        IStvAccount(receiver).execute(router, swapTxData, 0);
        uint256 balanceAfterSwap = IERC20(tokenOut).balanceOf(receiver);
        return balanceAfterSwap - balanceBeforeSwap;
    }

    function oneInch(address tokenIn, address tokenOut, address receiver, bytes memory exchangeData)
        external
        onlyVault
        returns (uint256)
    {
        if (exchangeData.length == 0) revert Errors.ExchangeDataMismatch();
        address router = IOperator(operator).getAddress("ONEINCHROUTER");
        uint256 tokenInBalanceBefore = IERC20(tokenIn).balanceOf(receiver);
        uint256 tokenOutBalanceBefore = IERC20(tokenOut).balanceOf(receiver);
        bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", router, type(uint256).max);
        IStvAccount(receiver).execute(tokenIn, approvalData, 0);
        IStvAccount(receiver).execute(router, exchangeData, 0);
        approvalData = abi.encodeWithSignature("approve(address,uint256)", router, 0);
        IStvAccount(receiver).execute(tokenIn, approvalData, 0);
        uint256 tokenInBalanceAfter = IERC20(tokenIn).balanceOf(receiver);
        uint256 tokenOutBalanceAfter = IERC20(tokenOut).balanceOf(receiver);
        if (tokenInBalanceAfter >= tokenInBalanceBefore) revert Errors.BalanceLessThanAmount();
        if (tokenOutBalanceAfter <= tokenOutBalanceBefore) revert Errors.BalanceLessThanAmount();
        return tokenOutBalanceAfter - tokenOutBalanceBefore;
    }
}
