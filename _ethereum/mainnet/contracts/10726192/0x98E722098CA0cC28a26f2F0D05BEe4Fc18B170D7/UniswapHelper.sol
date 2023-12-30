pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERC20 {
    function balanceOf(address wallet) external view returns (uint);
}

contract UniswapHelper {
    
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    struct Pair {
        address id;
        address token0;
        address token1;
        uint walletBalance;
    }
    
    function getAllPairsWithBalances(address wallet) external view returns (Pair[] memory pairsWithBalances) {
        uint pairsLength = factory.allPairsLength();
        Pair[] memory pairs = new Pair[](pairsLength);
        
        uint numOfPairsWithBalances;
        uint256[] memory pairsWithBalancesIndexes = new uint256[](pairsLength);
        for (uint i = 0; i < pairsLength; i++) {
            address pair = factory.allPairs(i);
            uint pairBalance = IERC20(pair).balanceOf(wallet);
            if (pairBalance == 0) {
                continue;
            }
            
            pairs[i] = Pair({
                id: pair,
                token0: IUniswapV2Pair(pair).token0(),
                token1: IUniswapV2Pair(pair).token1(),
                walletBalance: pairBalance
            });
            
            pairsWithBalancesIndexes[numOfPairsWithBalances] = i;
            numOfPairsWithBalances++;
        }
        
        pairsWithBalances = new Pair[](numOfPairsWithBalances);
        for (uint i = 0; i < numOfPairsWithBalances; i++) {
            pairsWithBalances[i] = pairs[pairsWithBalancesIndexes[i]];
        }
    }
    
    
}