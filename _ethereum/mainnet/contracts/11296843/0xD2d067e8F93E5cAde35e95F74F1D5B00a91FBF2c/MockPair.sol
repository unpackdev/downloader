//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IPair.sol";
import "./console.sol";

contract MockPair is IPair {

    using SafeMath for uint256;
    using SafeMath for uint112;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public token0;
    IERC20 public token1;
    uint public reserve0;
    uint public reserve1;

    constructor(address t0, address t1) public {
        (address _t0, address _t1) = t0 > t1 ? (t1,t0):(t0,t1);
        token0 = IERC20(_t0);
        token1 = IERC20(_t1);
        console.log("Pair token0", _t0);
        console.log("Pair token1", _t1);

    }

    function getReserves() external view override returns (uint, uint, uint) {
        return (reserve0, reserve1, block.timestamp);
    }

    function addLiquid(uint  amount0In, uint  amount1In) external override {
        console.log("Adding liquid", amount0In, amount1In);
        reserve0 = reserve0.add((amount0In));
        reserve1 = reserve1.add((amount1In));
    }

    function swap(uint  amount0Out, uint  amount1Out, address to, bytes calldata data) external override {
        
        require(amount0Out > 0 || amount1Out > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        (uint _reserve0, uint _reserve1,) = this.getReserves(); // gas savings
        console.log("Pair r0", _reserve0);
        console.log("Pair r1", _reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'INSUFFICIENT_LIQUIDITY');
        console.log("amount0Out", amount0Out);
        console.log("amount1Out", amount1Out);

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            IERC20 _token0 = token0;
            IERC20 _token1 = token1;
            require(to != address(_token0) && to != address(_token1), 'INVALID_TO');
            if (amount0Out > 0) _token0.safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _token1.safeTransfer(to, amount1Out); // optimistically transfer tokens
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        console.log("Balance0", balance0);
        console.log("Balance1", balance1);
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        console.log("Resulting amount0In", amount0In);
        console.log("Resulting amount1In", amount1In);

        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        reserve0 = balance0;
        reserve1 = balance1;

    }
}