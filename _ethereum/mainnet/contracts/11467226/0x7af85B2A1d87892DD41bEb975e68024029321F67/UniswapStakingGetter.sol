// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

struct PoolInfo {
    address contractAddr;
    address token0Addr;
    address token1Addr;
    string token0Symbol;
    string token1Symbol;
    uint8 token0Digits;
    uint8 token1Digits;
}

struct PoolBalance {
    address walletAddr;
    address contractAddr;
    uint tokenBalance;
    uint totalSupply;
    uint112 reserves0;
    uint112 reserves1;
}

contract UniswapStakingGetter {
    constructor() public {}

    function getPoolInfos(address[] memory contracts) public view returns (PoolInfo[] memory) {
        PoolInfo[] memory output = new PoolInfo[](contracts.length);
        for (uint i = 0; i < contracts.length; ++i) {
            IUniswapV2Pair pair = IUniswapV2Pair(contracts[i]);
            IERC20 token0 = IERC20(pair.token0());
            IERC20 token1 = IERC20(pair.token1());
            address token0Addr = pair.token0();
            address token1Addr = pair.token1();
            string memory token0Symbol = token0.symbol();
            string memory token1Symbol = token1.symbol();
            uint8 token0Digits = token0.decimals();
            uint8 token1Digits = token1.decimals();
            output[i] = PoolInfo(contracts[i], token0Addr, token1Addr, token0Symbol, token1Symbol, token0Digits, token1Digits);
        }

        return output;
    }

    function getBalance(address[] memory wallets, address[] memory pools) public view returns (PoolBalance[] memory) {
        PoolBalance[] memory output = new PoolBalance[](wallets.length * pools.length);
        uint outIdx = 0;
        
        for (uint i = 0; i < pools.length; ++i) {
            IUniswapV2Pair pair = IUniswapV2Pair(pools[i]);
            (uint112 reserves0, uint112 reserves1,) = pair.getReserves();
            uint totalSupply = pair.totalSupply();

            for (uint j = 0; j < wallets.length; ++j) {
                uint balance = pair.balanceOf(wallets[j]);
                output[outIdx++] = PoolBalance(wallets[j], pools[i], balance, totalSupply, reserves0, reserves1);
            }
        }

        return output;
    }
}