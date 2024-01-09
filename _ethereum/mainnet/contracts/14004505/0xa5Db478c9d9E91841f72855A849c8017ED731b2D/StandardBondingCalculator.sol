// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./IERC20Extended.sol";
import "./IUniswapV2ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

interface IBondingCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

contract StandardBondingCalculator is IBondingCalculator {

    using FixedPoint for *;
    using SafeMath for uint;
    using SafeMath for uint112;

    address public immutable KEEPER;

    constructor( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = a.div(2).add(1);
            while (b < c) {
                c = b;
                b = a.div(b).add(b).div(2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function getKValue( address _pair ) public view returns( uint k_ ) {
        uint token0 = IERC20Extended( IUniswapV2Pair( _pair ).token0() ).decimals();
        uint token1 = IERC20Extended( IUniswapV2Pair( _pair ).token1() ).decimals();
        
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        
        uint totalDecimals = token0.add( token1 );
        uint pairDecimal = IERC20Extended( _pair ).decimals();
        
        if (totalDecimals < pairDecimal) {
            uint decimals = pairDecimal.sub(totalDecimals);
            k_ = reserve0.mul(reserve1).mul(10 ** decimals);
        }
        else {
            uint decimals = totalDecimals.sub(pairDecimal);
            k_ = reserve0.mul(reserve1).div(10 ** decimals);
        }
    }

    function getTotalValue( address _pair ) public view returns ( uint _value ) {
        _value = sqrrt(getKValue( _pair )).mul(2);
    }

    function valuation( address _pair, uint amount_ ) external view override returns ( uint _value ) {
        uint totalValue = getTotalValue( _pair );
        uint totalSupply = IUniswapV2Pair( _pair ).totalSupply();

        _value = totalValue.mul( FixedPoint.fraction( amount_, totalSupply ).decode112with18() ).div( 1e18 );
    }

    function markdown( address _pair ) external view returns ( uint ) {
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();

        uint reserve;
        if ( IUniswapV2Pair( _pair ).token0() == KEEPER ) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }
        return reserve.mul( 2 * ( 10 ** IERC20Extended( KEEPER ).decimals() ) ).div( getTotalValue( _pair ) );
    }
}
