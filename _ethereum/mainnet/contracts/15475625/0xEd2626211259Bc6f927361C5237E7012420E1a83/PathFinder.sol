// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "./Ownable.sol";
import "./IPathFinder.sol";
import "./IQuoterV2.sol";
import "./Constants.sol";

contract PathFinder is IPathFinder, Ownable {
    IQuoterV2 public quoter;
    uint24[] private fees = [500, 3000, 10000];
    address[] private sharedTokens;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _quoter, address[] memory _tokens) {
        quoter = IQuoterV2(_quoter);
        sharedTokens = _tokens;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactInputPath(tokenIn, tokenOut, amount, tokens);
    }

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path) {
        address[] memory tokens = sharedTokens;
        path = bestExactOutputPath(tokenIn, tokenOut, amount, tokens);
    }

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_INPUT, tokenIn, tokenOut, amountIn, tokens);
    }

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] memory tokens
    ) public returns (TradePath memory path) {
        path = _bestV3Path(Constants.EXACT_OUTPUT, tokenOut, tokenIn, amountOut, tokens);
    }

    function getFees() public view returns (uint24[] memory) {
        return fees;
    }

    function getSharedTokens() public view returns (address[] memory) {
        return sharedTokens;
    }

    function updateFees(uint24[] memory _fees) external onlyOwner {
        fees = _fees;
    }

    function updateTokens(address[] memory tokens) external onlyOwner {
        sharedTokens = tokens;
    }

    function _bestV3Path(
        uint256 tradeType,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) internal returns (TradePath memory tradePath) {
        if (amount == 0 || tokenIn == address(0) || tokenOut == address(0) || tokenIn == tokenOut) return tradePath;

        tradePath.expectedAmount = tradeType == Constants.EXACT_INPUT ? 0 : Constants.MAX_UINT256;
        for (uint256 i = 0; i < fees.length; i++) {
            bytes memory path = abi.encodePacked(tokenIn, fees[i], tokenOut);
            (
                bool best,
                uint256 expectedAmount,
                uint160[] memory sqrtPriceX96AfterList,
                uint32[] memory initializedTicksCrossedList,
                uint256 gas
            ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
            if (best) {
                tradePath.expectedAmount = expectedAmount;
                tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                tradePath.gasEstimate = gas;
                tradePath.path = path;
            }
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenIn == tokens[i] || tokenOut == tokens[i]) continue;
            for (uint256 j = 0; j < fees.length; j++) {
                for (uint256 k = 0; k < fees.length; k++) {
                    bytes memory path = abi.encodePacked(tokenIn, fees[j], tokens[i], fees[k], tokenOut);
                    (
                        bool best,
                        uint256 expectedAmount,
                        uint160[] memory sqrtPriceX96AfterList,
                        uint32[] memory initializedTicksCrossedList,
                        uint256 gas
                    ) = _getAmount(tradeType, path, amount, tradePath.expectedAmount);
                    if (best) {
                        tradePath.expectedAmount = expectedAmount;
                        tradePath.sqrtPriceX96AfterList = sqrtPriceX96AfterList;
                        tradePath.initializedTicksCrossedList = initializedTicksCrossedList;
                        tradePath.gasEstimate = gas;
                        tradePath.path = path;
                    }
                }
            }
        }
    }

    function _getAmount(
        uint256 tradeType,
        bytes memory path,
        uint256 amount,
        uint256 bestAmount
    )
        internal
        returns (
            bool best,
            uint256 expectedAmount,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        expectedAmount = bestAmount;
        if (tradeType == Constants.EXACT_INPUT) {
            try quoter.quoteExactInput(path, amount) returns (
                uint256 amountOut,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountOut;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        } else if (tradeType == Constants.EXACT_OUTPUT) {
            try quoter.quoteExactOutput(path, amount) returns (
                uint256 amountIn,
                uint160[] memory afterList,
                uint32[] memory crossedList,
                uint256 gas
            ) {
                expectedAmount = amountIn;
                sqrtPriceX96AfterList = afterList;
                initializedTicksCrossedList = crossedList;
                gasEstimate = gas;
            } catch {}
        }

        best =
            (tradeType == Constants.EXACT_INPUT && expectedAmount > bestAmount) ||
            (tradeType == Constants.EXACT_OUTPUT && expectedAmount < bestAmount);
    }
}
