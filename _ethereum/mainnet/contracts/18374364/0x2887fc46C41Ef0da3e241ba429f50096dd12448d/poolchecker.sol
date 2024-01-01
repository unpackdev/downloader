// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV3Pool {
    function liquidity() external view returns (uint256);
}

import "./Ownable.sol";

contract TokenPoolChecker is Ownable{
    address public UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; 
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address

    uint24[] public feeTiers = [500, 3000, 10000];

    function isV2orV3(address token) public view returns (bool, uint) {
        bool isV2 = hasLiquidityV2(token);
        bool isV3 = hasLiquidityV3(token);

        if (isV2 && isV3) {
            uint256 v2Liquidity = getV2Liquidity(token);
            uint256 v3Liquidity = getV3Liquidity(token);
            
            // Return the pool with higher liquidity
            if (v2Liquidity > v3Liquidity) {
                return (true, 2); // Prefer V2
            } else {
                return (true, 3); // Prefer V3
            }
        } else if (isV2) {
            return (true, 2); // Only V2 is available
        } else if (isV3) {
            return (true, 3); // Only V3 is available
        } else {
            return (false, 0); // No pool available
        }
    }


    function hasLiquidityV2(address token) public view returns (bool) {
        IUniswapV2Factory factoryV2 = IUniswapV2Factory(UNISWAP_V2_FACTORY);
        address pair = factoryV2.getPair(token, WETH);
        return pair != address(0);
    }

    function hasLiquidityV3(address token) public view returns (bool) {
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        for (uint i = 0; i < feeTiers.length; i++) {
            address pool = factoryV3.getPool(token, WETH, feeTiers[i]);
            
            if (pool != address(0)) {
                return true;
            }
        }
        return false;
    }

    function preferredPool(address token) public view returns (uint) {
        (bool isPool, uint poolVersion) = isV2orV3(token);

        if (!isPool) return 0; // No pool available

        if (poolVersion == 3) {
            uint256 v2Liquidity = getV2Liquidity(token);
            uint256 v3Liquidity = getV3Liquidity(token);

            // Compare v2 and v3 liquidity and return the preferred version
            if (v2Liquidity > v3Liquidity) {
                return 2; // Prefer V2
            } else {
                return 3; // Prefer V3
            }
        } else {
            return poolVersion; // Only one version is available
        }
    }

    function getV2Liquidity(address token) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token, WETH));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        return token < WETH ? reserve0 : reserve1;
    }

    function getV3Liquidity(address token) public view returns (uint256) {
        uint256 totalLiquidity = 0;
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        for (uint i = 0; i < feeTiers.length; i++) {
            address poolAddress = factoryV3.getPool(token, WETH, feeTiers[i]);
            if (poolAddress != address(0)) {
                IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
                totalLiquidity += pool.liquidity();
            }
        }
        return totalLiquidity;
    }

    function updateUniswapV2Factory(address _uniswapV2Factory) public onlyOwner {
        UNISWAP_V2_FACTORY = _uniswapV2Factory;
    }
    function updateUniswapV3Factory(address _uniswapV3Factory) public onlyOwner {
        UNISWAP_V3_FACTORY = _uniswapV3Factory;
    }
}
