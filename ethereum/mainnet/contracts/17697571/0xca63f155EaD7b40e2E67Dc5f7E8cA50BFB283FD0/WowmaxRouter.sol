// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IWETH.sol";
import "./IWowmaxRouter.sol";

import "./UniswapV2.sol";
import "./UniswapV3.sol";
import "./Curve.sol";
import "./PancakeSwapStable.sol";
import "./DODOV2.sol";
import "./DODOV1.sol";
import "./Hashflow.sol";
import "./Saddle.sol";
import "./Wombat.sol";
import "./Level.sol";
import "./Fulcrom.sol";
import "./WooFi.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./WowmaxSwapReentrancyGuard.sol";

/// @title WOWMAX Router
/// @notice Router for stateless execution of swaps against multiple DEX protocols
contract WowmaxRouter is IWowmaxRouter, Ownable, WowmaxSwapReentrancyGuard {
    IWETH public WETH;
    address public treasury;

    bytes32 internal constant UNISWAP_V2 = "UNISWAP_V2";
    bytes32 internal constant UNISWAP_V3 = "UNISWAP_V3";
    bytes32 internal constant UNISWAP_V2_ROUTER = "UNISWAP_V2_ROUTER";
    bytes32 internal constant CURVE = "CURVE";
    bytes32 internal constant DODO_V1 = "DODO_V1";
    bytes32 internal constant DODO_V2 = "DODO_V2";
    bytes32 internal constant HASHFLOW = "HASHFLOW";
    bytes32 internal constant PANCAKESWAP_STABLE = "PANCAKESWAP_STABLE";
    bytes32 internal constant SADDLE = "SADDLE";
    bytes32 internal constant WOMBAT = "WOMBAT";
    bytes32 internal constant LEVEL = "LEVEL";
    bytes32 internal constant FULCROM = "FULCROM";
    bytes32 internal constant WOOFI = "WOOFI";

    using SafeERC20 for IERC20;

    constructor(address _weth, address _treasury) {
        require(_weth != address(0), "WOWMAX: Wrong WETH address");
        require(_treasury != address(0), "WOWMAX: Wrong treasury address");

        WETH = IWETH(_weth);
        treasury = _treasury;
    }

    receive() external payable {
        require(_msgSender() == payable(address(WETH)), "WOWMAX: Forbidden token transfer");
        // only accept native chain tokens via fallback from the wrapper contract
    }

    // @inheritdoc IWowmaxRouter
    function swap(
        ExchangeRequest calldata request
    ) external payable override reentrancyProtectedSwap returns (uint256[] memory amountsOut) {
        uint256 amountIn = receiveTokens(request);
        for (uint256 i = 0; i < request.exchangeRoutes.length; i++) {
            exchange(request.exchangeRoutes[i]);
        }
        amountsOut = sendTokens(request);

        emit SwapExecuted(
            msg.sender,
            request.from == address(0) ? address(WETH) : request.from,
            amountIn,
            request.to,
            amountsOut
        );
    }

    // @dev receives source tokens from account or wraps received value
    function receiveTokens(ExchangeRequest calldata request) private returns (uint256) {
        uint256 amountIn;
        if (msg.value > 0 && request.from == address(0) && request.amountIn == 0) {
            amountIn = msg.value;
            WETH.deposit{ value: amountIn }();
        } else {
            if (request.amountIn > 0) {
                amountIn = request.amountIn;
                IERC20(request.from).safeTransferFrom(msg.sender, address(this), amountIn);
            }
        }
        return amountIn;
    }

    // @dev transfers received tokens back to the caller
    function sendTokens(ExchangeRequest calldata request) private returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](request.to.length);
        uint256 amountOut;
        IERC20 token;
        for (uint256 i = 0; i < request.to.length; i++) {
            token = IERC20(request.to[i]);
            amountOut = token.balanceOf(address(this));

            uint256 amountExtra;
            if (amountOut > request.amountOutExpected[i]) {
                amountExtra = amountOut - request.amountOutExpected[i];
                amountsOut[i] = request.amountOutExpected[i];
            } else {
                require(
                    amountOut >= (request.amountOutExpected[i] * (10000 - request.slippage[i])) / 10000,
                    "WOWMAX: Insufficient output amount"
                );
                amountsOut[i] = amountOut;
            }

            if (address(token) == address(WETH)) {
                WETH.withdraw(amountOut);
            }

            transfer(token, treasury, amountExtra);
            transfer(token, msg.sender, amountsOut[i]);
        }
    }

    // @dev transfer token to a recipient, unwrapping native token if necessary
    function transfer(IERC20 token, address to, uint256 amount) private {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) {
            return;
        }
        if (address(token) == address(WETH)) {
            //slither-disable-next-line arbitrary-send-eth //recipient is either a msg.sender or a treasury
            payable(to).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    // @dev executes a single exchange route
    function exchange(ExchangeRoute calldata exchangeRoute) private returns (uint256) {
        uint256 amountIn = IERC20(exchangeRoute.from).balanceOf(address(this));
        uint256 amountOut;
        for (uint256 i = 0; i < exchangeRoute.swaps.length; i++) {
            amountOut += executeSwap(
                exchangeRoute.from,
                (amountIn * exchangeRoute.swaps[i].part) / exchangeRoute.parts,
                exchangeRoute.swaps[i]
            );
        }
        return amountOut;
    }

    // @dev executes a single swap
    function executeSwap(address from, uint256 amountIn, Swap calldata swapData) private returns (uint256) {
        if (swapData.family == UNISWAP_V3) {
            return UniswapV3.swap(amountIn, swapData);
        } else if (swapData.family == HASHFLOW) {
            return Hashflow.swap(from, amountIn, swapData);
        } else if (swapData.family == WOMBAT) {
            return Wombat.swap(from, amountIn, swapData);
        } else if (swapData.family == LEVEL) {
            return Level.swap(from, amountIn, swapData);
        } else if (swapData.family == DODO_V2) {
            return DODOV2.swap(from, amountIn, swapData);
        } else if (swapData.family == WOOFI) {
            return WooFi.swap(from, amountIn, swapData);
        } else if (swapData.family == UNISWAP_V2) {
            return UniswapV2.swap(from, amountIn, swapData);
        } else if (swapData.family == CURVE) {
            return Curve.swap(from, amountIn, swapData);
        } else if (swapData.family == PANCAKESWAP_STABLE) {
            return PancakeSwapStable.swap(from, amountIn, swapData);
        } else if (swapData.family == DODO_V1) {
            return DODOV1.swap(from, amountIn, swapData);
        } else if (swapData.family == SADDLE) {
            return Saddle.swap(from, amountIn, swapData);
        } else if (swapData.family == FULCROM) {
            return Fulcrom.swap(from, amountIn, swapData);
        } else if (swapData.family == UNISWAP_V2_ROUTER) {
            return UniswapV2.routerSwap(from, amountIn, swapData);
        } else {
            revert("WOWMAX: Unknown DEX family");
        }
    }

    // Callbacks

    // @dev callback for UniswapV3, is not allowed to be executed outside of a swap operation
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external onlyDuringSwap {
        UniswapV3.invokeCallback(amount0Delta, amount1Delta, _data);
    }

    // @dev callback for PancakeSwapV3, is not allowed to be executed outside of a swap operation
    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external onlyDuringSwap {
        UniswapV3.invokeCallback(amount0Delta, amount1Delta, _data);
    }

    // Admin functions

    // @dev withdraws tokens from the contract, in case of leftovers after a swap, or invalid swap requests
    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(treasury, amount);
    }

    // @dev withdraws chain native tokens from the contract, in case of leftovers after a swap, or invalid swap requests
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(treasury).transfer(amount);
    }
}
