// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

/**
 * @dev Uniswap helpers
 */
library UniswapLib {

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function ethQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        (tokenReserve, ethReserve, ) = IUniswapV2Pair(_pair).getReserves();
        ethereum = quote(tokenAmount, tokenReserve, ethReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function WETH() external pure returns (address weth) {
        weth = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).WETH();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IUniswapV2Factory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IUniswapV2Pair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForETHToToken(address token) external pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}
