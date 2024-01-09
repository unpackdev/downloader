// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./IERC20Extended.sol";
import "./IUniswapV2ERC20.sol";
import "./IUniswapV2Pair.sol";


contract LPCalculator {

    using SafeMath for uint;
    address public immutable KEEPER;
    uint public constant keeperDecimals = 9;


    constructor ( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
    }


    function getReserve( address _pair ) public view returns ( address reserveToken, uint reserve ) {
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        if ( IUniswapV2Pair( _pair ).token0() == KEEPER ) {
            reserve = reserve1;
            reserveToken = IUniswapV2Pair( _pair ).token1();
        } else {
            reserve = reserve0;
            reserveToken = IUniswapV2Pair( _pair ).token0();
        }
    }

    function valuationUSD( address _pair, uint _amount ) external view returns ( uint ) {
        uint totalSupply = IUniswapV2Pair( _pair ).totalSupply();
        ( address reserveToken, uint reserve ) = getReserve( _pair );
        return _amount.mul( reserve ).mul(2).mul( 10 ** keeperDecimals ).div( totalSupply ).div( 10 ** IERC20Extended( reserveToken ).decimals() );
    }
}
