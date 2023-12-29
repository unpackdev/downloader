// SPDX-License-Identifier: MIT
/*


██╗  ██╗███████╗███╗   ██╗    ██████╗ ██████╗ ██╗ ██████╗███████╗     ██████╗ ██████╗  █████╗  ██████╗██╗     ███████╗    
╚██╗██╔╝██╔════╝████╗  ██║    ██╔══██╗██╔══██╗██║██╔════╝██╔════╝    ██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║     ██╔════╝    
 ╚███╔╝ █████╗  ██╔██╗ ██║    ██████╔╝██████╔╝██║██║     █████╗      ██║   ██║██████╔╝███████║██║     ██║     █████╗      
 ██╔██╗ ██╔══╝  ██║╚██╗██║    ██╔═══╝ ██╔══██╗██║██║     ██╔══╝      ██║   ██║██╔══██╗██╔══██║██║     ██║     ██╔══╝      
██╔╝ ██╗███████╗██║ ╚████║    ██║     ██║  ██║██║╚██████╗███████╗    ╚██████╔╝██║  ██║██║  ██║╚██████╗███████╗███████╗    
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝    
                                                                                                                          

*/
pragma solidity ^0.8.17;

import "./IUniswapV2Pair.sol";
import "./IUniswapV3Pool.sol";





contract PriceOracle {
    // Assuming these addresses are for the pairs you're interested in
    address private constant V2_PAIR = 0xC0d776E2223c9a2ad13433DAb7eC08cB9C5E76ae; // V2 XEN/ETH Pair
    address private constant V3_XEN_ETH = 0x2a9d2ba41aba912316D16742f259412B681898Db; // V3 XEN/ETH Pool
    address private constant XenAddress = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8; // Xen crypto on ETH

    function calculateV2Price() public view returns (uint256) {
    // Access Uniswap V2 Pair for this contract
    IUniswapV2Pair pair = IUniswapV2Pair(V2_PAIR);

    // The IUniswapV2Pair.getReserves function returns the liquidity reserves of token0 and token1 in the pair
    // token0 is the token with the lower sort order of the pair
    (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

    // Check which token is XEN
    address token0 = pair.token0();
    address token1 = pair.token1();
    
    if (token0 == XenAddress) {  // Xen Address denoting the XEN token address 
        require(reserve1 != 0, "Reserve for token1 is 0");
        // The price is calculated as the ratio of the reserves of token0 to token1
        // This will return the price of XEN in terms of token1
        return uint256(reserve0) / uint256(reserve1); // Returns the price as token0/token1 (XEN/token1)
    } else if (token1 == XenAddress) {
        require(reserve0 != 0, "Reserve for token0 is 0");
        // The price is calculated as the ratio of the reserves of token1 to token0
        // This will return the price of XEN in terms of token0
        return uint256(reserve1) / uint256(reserve0); // Returns the price as token1/token0 (XEN/token0)
    } else {
        revert("Neither token in the Uniswap V2 pair is XEN");
    }
}

    function calculateV3Price(IUniswapV3Pool pool, bool isToken0Xen) public view returns (uint256) {
        // The IUniswapV3Pool.slot0 function returns the current state of the pool,
        // which includes the square root price as a Q64.96 fixed-point number
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        // Get the token0 and token1 addresses of the pool
        (address token0,) = (pool.token0(), pool.token1());

        // Check which token is XEN in the pair
        isToken0Xen = token0 == XenAddress;
        

        // To correctly calculate the price, get decimals of both tokens, adjust for Q64.96 and according to isToken0Xen
        uint256 decimalsAdjustment =
            isToken0Xen
                ? 96 + (18 * 2)
                : 96 + (18 * 2) - 18 * 2;

        // The square root price is squared to get the actual price,
        // and it is shifted right by 'decimalsAdjustment' to convert from Q64.96 format to an integer
        uint256 priceToken0Token1 = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) / (1 << decimalsAdjustment));

        // The actual price is calculated differently depending on which token in the pair is XEN
        if (!isToken0Xen) {
            // If token0 is XEN, the price is already token0/token1 (XEN/Other) and can be returned directly
            return priceToken0Token1; // Return XEN/Other price
        } else {
            // If token1 is XEN, the price is token1/token0 (Other/XEN),
            // so we return the reciprocal to get the price as XEN/Other
            require(priceToken0Token1 != 0, "Price is 0");
            return 1e18 / priceToken0Token1; // Return Other/XEN price
        }
    }

    function calculateAveragePrice() public view returns (uint256) {
        uint256 total; // Initialize total price accumulator
        uint256 count; // Initialize counter for the number of price points

        // V2 price calculation
        uint256 v2Price = calculateV2Price(); // Get the XEN/ETH price from the Uniswap V2 pool
        if (v2Price != 0) {
            total += v2Price; // Add the price to the total if it is not zero
            count++; // Increase the price point count by one
        }

        // V3 XEN/ETH price calculation
        uint256 xenEthPrice = calculateV3Price(IUniswapV3Pool(V3_XEN_ETH), true); // Get the XEN/ETH price from the Uniswap V3 pool
        if (xenEthPrice != 0) {
            total += xenEthPrice; // Add the price to the total if it is not zero
            count++; // Increase the price point count by one
        }

        require(count != 0, "No valid price points");
        return total / count;
    }
}
