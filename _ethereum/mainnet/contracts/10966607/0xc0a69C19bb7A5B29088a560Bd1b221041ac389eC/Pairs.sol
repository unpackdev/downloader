pragma solidity =0.7.2;

// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Pairs {
    
    function getPair(address pairAddress) public view returns 
        ( address token0
        , address token1
        , uint112 reserve0
        , uint112 reserve1
        , uint balance0
        , uint balance1
        ) {
        
        IUniswapV2Pair _pair = IUniswapV2Pair(pairAddress);
        
        token0 = _pair.token0();
        token1 = _pair.token1();
        (reserve0, reserve1,) = _pair.getReserves();
        balance0 = _safeBalanceOf(token0, pairAddress);
        balance1 = _safeBalanceOf(token1, pairAddress);
    }
    
    function getAllPairs(address factoryAddress, uint fromIndex, uint toIndex) external view returns 
        ( address[] memory pairs
        , address[] memory tokens0
        , address[] memory tokens1
        , uint112[] memory reserves0
        , uint112[] memory reserves1
        , uint[] memory balances0
        , uint[] memory balances1
        ) {
            
        IUniswapV2Factory _factory = IUniswapV2Factory(factoryAddress);
        uint _count = _factory.allPairsLength();
        uint _to = toIndex < _count ? toIndex : _count - 1;
        uint _from = fromIndex <= _to ? fromIndex : _to;
        uint _length = _to - _from + 1;
        
        
        pairs = new address[](_length);
        
        tokens0 = new address[](_length);
        tokens1 = new address[](_length);
        reserves0 = new uint112[](_length);
        reserves1 = new uint112[](_length);
        
        for (uint i = 0; i < _length; i++) {
            pairs[i] = _factory.allPairs(i + _from);
            (tokens0[i], tokens1[i],reserves0[i],reserves1[i],,) = getPair(pairs[i]);
        }
        
        balances0 = new uint[](_length);
        balances1 = new uint[](_length);
        
        for (uint i = 0; i < _length; i++) {
            address _pair = pairs[i];
            (,,,,balances0[i], balances1[i]) = getPair(_pair);
        }
    }
    
    function _safeBalanceOf(address token, address owner) private view returns (uint) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", owner));
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint));
        } else {
            return 0;
        }
    }
}