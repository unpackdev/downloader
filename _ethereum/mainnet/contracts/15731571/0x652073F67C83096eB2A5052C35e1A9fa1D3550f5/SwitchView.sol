// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./SwitchRoot.sol";
import "./IERC20.sol";

contract SwitchView is SwitchRoot {
    using UniversalERC20 for IERC20;
    using UniswapExchangeLib for IUniswapExchange;

    function(CalculateArgs memory args) view returns(uint256[] memory)[] pathFunctions;

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories
    ) SwitchRoot(_weth, _otherToken, _pathCount, _pathSplit, _factories) public {
        if (_pathCount == 2) {
            pathFunctions.push(calculate);
            pathFunctions.push(calculateETH);
        } else if (_pathCount == 3) {
            pathFunctions.push(calculate);
            pathFunctions.push(calculateETH);
            pathFunctions.push(calculateOtherToken);
        } else {
            revert("path count needs to be either 2 or 3");
        }
    }

//    function(CalculateArgs memory args) view returns(uint256[] memory)[PATHS_COUNT] pathFunctions = [
//        calculate,
//        calculateETH,
//        calculateRealETH
//    ];

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = _getExpectedReturn(
            ReturnArgs({
            fromToken: fromToken,
            destToken: destToken,
            amount: amount,
            parts: parts
            })
        );
    }

    function _getExpectedReturn(
        ReturnArgs memory returnArgs
    )
        internal
        view
        returns (
            uint256 returnAmount,
            uint256[] memory mergedDistribution
        )
    {
        uint256[] memory distribution = new uint256[](dexCount*pathCount*pathSplit);
        mergedDistribution = new uint256[](dexCount*pathCount);

        if (returnArgs.fromToken == returnArgs.destToken) {
            return (returnArgs.amount, distribution);
        }

        int256[][] memory matrix = new int256[][](dexCount*pathCount*pathSplit);
        bool atLeastOnePositive = false;
        for (uint l = 0; l < dexCount; l++) {
            uint256[] memory rets;
            for (uint m = 0; m < pathCount; m++) {
                for (uint k = 0; k < pathSplit; k++) {
                    uint256 i = l*pathCount*pathSplit+m*pathSplit+k;
                    rets = pathFunctions[m](CalculateArgs({
                        fromToken:returnArgs.fromToken,
                        destToken:returnArgs.destToken,
                        factory:IUniswapFactory(factories[l]),
                        amount:returnArgs.amount,
                        parts:returnArgs.parts
                    }));

                    // Prepend zero
                    matrix[i] = new int256[](returnArgs.parts + 1);
                    for (uint j = 0; j < rets.length; j++) {
                        matrix[i][j + 1] = int256(rets[j]);
                        atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
                    }
                }
            }
        }

        if (!atLeastOnePositive) {
            for (uint i = 0; i < dexCount*pathCount*pathSplit;) {
                for (uint j = 1; j < returnArgs.parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
                unchecked {
                    i++;
                }
            }
        }

        (, distribution) = _findBestDistribution(returnArgs.parts, matrix);

        returnAmount = _getReturnByDistribution(matrix, distribution);

        for (uint i = 0; i < dexCount*pathCount*pathSplit;) {
            mergedDistribution[i/pathSplit] += distribution[i];
            unchecked {
                i++;
            }
        }
        return (returnAmount, mergedDistribution);
    }

    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256[] distribution;
        int256[][] matrix;
        function(CalculateArgs memory) view returns(uint256[] memory) pathFunctions;
        IUniswapFactory[] dexes;
    }

    function _getReturnByDistribution(int256[][] memory matrix, uint256[] memory distribution) internal view returns(uint256 returnAmount) {
        for (uint i = 0; i < dexCount*pathCount*pathSplit;) {
            if (distribution[i] > 0) {
                int256 value = matrix[i][distribution[i]];
                returnAmount += uint256(
                        (value == VERY_NEGATIVE_VALUE ? int256(0) : value)
                    );

            }
            unchecked {
                i++;
            }
        }
    }

    // View Helpers

    struct Balances {
        uint256 src;
        uint256 dst;
    }



    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[100] memory rets)
    {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _calculateUniswapFormula(
        uint256 fromBalance,
        uint256 toBalance,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }
        return amount * toBalance * 997 / (
            fromBalance * 1000 + amount *997
        );
    }

    function calculate(CalculateArgs memory args) public view returns(uint256[] memory rets) {
        return _calculate(
            args.fromToken,
            args.destToken,
            args.factory,
            _linearInterpolation(args.amount, args.parts)
        );
    }

    function calculateETH(CalculateArgs memory args) internal view returns(uint256[] memory rets) {
        if (args.fromToken.isETH() || args.fromToken == weth || args.destToken.isETH() || args.destToken == weth) {
            return new uint256[](args.parts);
        }

        return _calculateOverMidToken(
            args.fromToken,
            weth,
            args.destToken,
            args.factory,
            args.amount,
            args.parts
        );
    }

    function calculateOtherToken(CalculateArgs memory args) internal view returns(uint256[] memory rets) {
        if (args.fromToken == otherToken || args.destToken == otherToken) {
            return new uint256[](args.parts);
        }

        return _calculateOverMidToken(
            args.fromToken,
            otherToken,
            args.destToken,
            args.factory,
            args.amount,
            args.parts
        );
    }

    function _calculate(
        IERC20 fromToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256[] memory amounts
    )
        internal
        view
        returns (uint256[] memory rets)
    {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, destTokenReal);
        if (address(exchange) != address(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return rets;
        }
    }

    function _calculateOverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256 amount,
        uint256 parts
    )
        internal
        view
        returns (uint256[] memory rets)
    {
        rets = _linearInterpolation(amount, parts);

        rets = _calculate(fromToken, midToken, factory, rets);
        rets = _calculate(midToken, destToken, factory, rets);
        return rets;
    }
}
