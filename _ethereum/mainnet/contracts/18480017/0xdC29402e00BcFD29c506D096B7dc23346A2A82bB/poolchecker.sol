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
    function fee() external view returns (uint24);
}

import "./Ownable.sol";

contract TokenPoolChecker is Ownable {
    address public UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint24[] public feeTiers = [100, 500, 3000, 10000];
    
    mapping(address => mapping(address => uint24)) public bestFeeTiers;
    enum PoolVersion { None, V2, V3 }

    struct V3Data {
        address[] v3Path;
        uint24[] poolFees;
    }

    function getPoolVersion(address token) public view returns (PoolVersion) {
        bool isV2 = hasLiquidityV2(token);
        bool isV3;
        (isV3, ) = hasLiquidityV3(token);

        if (isV2 && isV3) {
            uint256 v2Liquidity = getV2Liquidity(token);
            (, address baseToken) = hasLiquidityV3(token);
            uint256 v3Liquidity = getV3Liquidity(token, baseToken);

            return v2Liquidity > v3Liquidity ? PoolVersion.V2 : PoolVersion.V3;
        } else if (isV2) {
            return PoolVersion.V2;
        } else if (isV3) {
            return PoolVersion.V3;
        } else {
            return PoolVersion.None;
        }
    }

    function getV3Data(address token) public view returns (V3Data memory) {
        address baseToken;
        bool hasLiq;
        (hasLiq, baseToken) = hasLiquidityV3(token);
        // Check if the token has V3 liquidity with any base token
        if(!hasLiq) {
            return V3Data({v3Path: new address[](0), poolFees: new uint24[](0)});
        }
        return V3Data({
            v3Path: determineV3SwapPath(token, baseToken), 
            poolFees: determineV3SwapFees(token, baseToken)  
        });
    }

    function hasLiquidityV2(address token) public view returns (bool) {
        IUniswapV2Factory factoryV2 = IUniswapV2Factory(UNISWAP_V2_FACTORY);
        address pair = factoryV2.getPair(token, WETH);
        return pair != address(0);
    }

    function hasLiquidityV3(address token) public view returns (bool, address) {
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        for (uint i = 0; i < feeTiers.length; i++) {
            if (factoryV3.getPool(token, WETH, feeTiers[i]) != address(0)) {
                return (true, WETH);
            } else if (factoryV3.getPool(token, USDC, feeTiers[i]) != address(0)) {
                return (true, USDC);
            } else if (factoryV3.getPool(token, USDT, feeTiers[i]) != address(0)) {
                return (true, USDT);
            }
        }
        return (false, address(0));
    }

    function getV2Liquidity(address token) public view returns (uint256) {
        address pairAddress = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token, WETH);
        (address token0, ) = sortTokens(token, WETH);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        return token == token0 ? reserve0 : reserve1;
    }

    function determineV3SwapFees(address tokenIn, address baseToken) public view returns(uint24[] memory) {
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
            
        uint24 bestFeeTierTokenToBase = 0;
        uint24 bestFeeTierBaseToWETH = 0;
        uint256 maxLiquidityTokenToBase = 0;
        uint256 maxLiquidityBaseToWETH = 0;

        IUniswapV3Pool poolTokenToBase;
        IUniswapV3Pool poolBaseToWETH;

        for (uint i = 0; i < feeTiers.length; i++) {
            address poolAddressTokenToBase = factoryV3.getPool(tokenIn, baseToken, feeTiers[i]);
            address poolAddressBaseToWETH = factoryV3.getPool(baseToken, WETH, feeTiers[i]);

            if (poolAddressTokenToBase != address(0)) {
                poolTokenToBase = IUniswapV3Pool(poolAddressTokenToBase);
                uint256 currentLiquidity = poolTokenToBase.liquidity();
                if (currentLiquidity > maxLiquidityTokenToBase) {
                    maxLiquidityTokenToBase = currentLiquidity;
                    bestFeeTierTokenToBase = feeTiers[i];
                }
            }
            if (poolAddressBaseToWETH != address(0)) {
                poolBaseToWETH = IUniswapV3Pool(poolAddressBaseToWETH);
                uint256 currentLiquidity = poolBaseToWETH.liquidity();
                    
                if (currentLiquidity > maxLiquidityBaseToWETH) {
                    maxLiquidityBaseToWETH = currentLiquidity;
                    bestFeeTierBaseToWETH = feeTiers[i];
                }
            }
        }

        uint24[] memory fees = (baseToken == WETH) ? new uint24[](1) : new uint24[](2);
        fees[0] = bestFeeTierTokenToBase;
        if(baseToken != WETH) {
            fees[1] = bestFeeTierBaseToWETH;
        }
        
        return fees;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
    function updateUniswapV2Factory(address _uniswapV2Factory) public onlyOwner {
        UNISWAP_V2_FACTORY = _uniswapV2Factory;
    }
    function updateUniswapV3Factory(address _uniswapV3Factory) public onlyOwner {
        UNISWAP_V3_FACTORY = _uniswapV3Factory;
    }
    function determineV3SwapPath(address tokenIn, address baseToken) public view returns(address[] memory) {
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        
        for (uint i = 0; i < feeTiers.length; i++) {
            address poolAddress = factoryV3.getPool(tokenIn, baseToken, feeTiers[i]);
            
            // Direct path for tokenIn -> WETH
            if (poolAddress != address(0) && baseToken == WETH) {
                address[] memory path = new address[](2);
                path[0] = tokenIn;
                path[1] = WETH;
                return path;
            }
            
            // Path for tokenIn -> USDC -> WETH
            if (poolAddress != address(0) && (baseToken == USDC || baseToken == USDT) ) {
                address[] memory path = new address[](3);
                path[0] = tokenIn;
                path[1] = baseToken;
                path[2] = WETH;
                return path;
            }
        }
        return new address[](0);
    }
    function getV3Liquidity(address tokenin, address basetoken) public view returns (uint256) {
        uint256 totalLiquidity = 0;
        IUniswapV3Factory factoryV3 = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        for (uint i = 0; i < feeTiers.length; i++) {
            address poolAddress = factoryV3.getPool(tokenin, basetoken, feeTiers[i]);
            if (poolAddress != address(0)) {
                IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
                totalLiquidity += pool.liquidity();
            }
        }
        return totalLiquidity;
    }
}