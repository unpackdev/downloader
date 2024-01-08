pragma solidity >=0.5.0;

import "./IUniswapV2Pair.sol";

library UniswapStyleLib {
    address constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Identical address!");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address!");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pair).getReserves();

        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1_000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1_000;

        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint256 amountIn,
        bytes32 amms,
        address[] memory tokens
    ) internal view returns (uint256[] memory amounts, address[] memory pairs) {
        require(tokens.length >= 2, "token path too short");

        amounts = new uint256[](tokens.length);
        amounts[0] = amountIn;

        pairs = new address[](tokens.length - 1);

        for (uint256 i; i < tokens.length - 1; i++) {
            address inToken = tokens[i];
            address outToken = tokens[i + 1];

            address pair =
                amms[i] == 0
                    ? pairForUni(inToken, outToken)
                    : pairForSushi(inToken, outToken);
            pairs[i] = pair;

            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(pair, inToken, outToken);

            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint256 amountOut,
        bytes32 amms,
        address[] memory tokens
    ) internal view returns (uint256[] memory amounts, address[] memory pairs) {
        require(tokens.length >= 2, "token path too short");

        amounts = new uint256[](tokens.length);
        amounts[amounts.length - 1] = amountOut;

        pairs = new address[](tokens.length - 1);

        for (uint256 i = tokens.length - 1; i > 0; i--) {
            address inToken = tokens[i - 1];
            address outToken = tokens[i];

            address pair =
                amms[i - 1] == 0
                    ? pairForUni(inToken, outToken)
                    : pairForSushi(inToken, outToken);
            pairs[i - 1] = pair;

            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(pair, inToken, outToken);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForUni(address tokenA, address tokenB)
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_FACTORY,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    function pairForSushi(address tokenA, address tokenB)
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            SUSHI_FACTORY,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }
}
