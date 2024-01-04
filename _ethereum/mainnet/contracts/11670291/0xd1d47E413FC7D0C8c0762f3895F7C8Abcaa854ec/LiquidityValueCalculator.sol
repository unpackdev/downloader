//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "./ILiquidityValueCalculator.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./console.sol";

contract LiquidityValueCalculator is ILiquidityValueCalculator {
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant ROOK_ADDRESS = 0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a;
    constructor() public {
        console.log("Deploying a LiquidityValueCalculator with test msg");
    }
    function ethRookPairInfo() override external returns (uint pairTotalSupply) {
        console.log("innit");
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address wethToken = uniswapRouter.WETH();
        if (IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).getPair(wethToken, ROOK_ADDRESS) == address(0)) {
            IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).createPair(wethToken, ROOK_ADDRESS);
        }
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_FACTORY_ADDRESS, wethToken, ROOK_ADDRESS));
        pairTotalSupply = pair.totalSupply();
        console.log(pairTotalSupply);
        console.log("TotalSupply is: '%d'", pairTotalSupply);
    }
}
