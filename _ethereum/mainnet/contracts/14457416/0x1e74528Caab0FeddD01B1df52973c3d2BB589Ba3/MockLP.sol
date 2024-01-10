// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./Ownable.sol";

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

contract MockLP is Ownable, IUniswapV2Pair {

    uint112 public reserve0;
    uint112 public reserve1;
    address public token_0;
    address public token_1;

    function setParameters(address _token0, uint112 _reserve0, address _token1, uint112 _reserve1) external onlyOwner {
        token_0 = _token0;
        reserve0 = _reserve0;
        token_1 = _token1;
        reserve1 = _reserve1;
    }


    function getReserves() external override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = uint32(block.timestamp);
    }

    function token0() external override view returns ( address ) {
        return token_0;
    }

    function token1() external override view returns ( address ) {
        return token_1;
    }

    function totalSupply() external override view returns (uint) {
        return 0;
    }

}
