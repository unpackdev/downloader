// SPDX-License-Identifier: SEE LICENSE IN LICENSE FILE
pragma solidity ^0.8.4;
// This ABDKMath64x64 Library has a differnet license in /libraies/LICENSE.md
import "./ABDKMath64x64.sol";

library XpMath {
    //64 bit decimal number pricision is 0.00000000000000000005421
    //pi=       3.1415926535897932384626433832795 decimal= 2611928677177517772=  243f6f4b15d266cc
    //halfpi=   1.5707963267948966192313216916398 decimal= 10529354856943306017= 921fc8749a23c521
    //quarterpi=0.7853981633974483096156608458198 decimal= 14488067946826200140= c90ff5095c4c744c
    //twopi=    6.2831853071795864769252867665590 decimal= 5223857354355035545=  487ede962ba4cd99
    int128 private constant PI =        0x0000000000000003243F6F4B15D266CC;
    int128 private constant HALFPI =    0x0000000000000001921fc8749a23c521;
    int128 private constant QUARTERPI = 0x0000000000000000c90ff5095c4c744c;
    int128 private constant TWOPI =     0x0000000000000006487EDE962BA4CD99;

    //------------------FUNCTIONS FROM ABDKMath64x64----------------------------//
    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        return ABDKMath64x64.fromInt(x);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return ABDKMath64x64.toInt(x);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        return ABDKMath64x64.fromUInt(x);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        return ABDKMath64x64.toUInt(x);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        return ABDKMath64x64.from128x128(x);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return ABDKMath64x64.to128x128(x);
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.add(x, y);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.sub(x, y);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.mul(x, y);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        return ABDKMath64x64.muli(x, y);
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        return ABDKMath64x64.mulu(x, y);
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.div(x, y);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        return ABDKMath64x64.divi(x, y);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        return ABDKMath64x64.divu(x, y);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.neg(x);
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.abs(x);
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.inv(x);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.avg(x, y);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        return ABDKMath64x64.gavg(x, y);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        return ABDKMath64x64.pow(x, y);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.sqrt(x);
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.log_2(x);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.ln(x);
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.exp_2(x);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.exp(x);
    }

    //------------------FUNCTIONS FROM ABDKMath64x64 END-------------------------//

    /**
     * Calculate sine of x.  Revert on overflow.
     * use y = 0.987862x - 0.155271x^3 + 0.00564312x^5
     * a=0.987862 = 18222874008485519276= fce4a75c9e7a5fac
     * b=0.155271 = 2864250138350857775 = 27bfdc534c442e2f
     * c=0.00564312=104097399003873824  = 0171d40869ab0220
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sin(int128 x) internal pure returns (int128) {
        //this approximation only for x in range [-pi/2,pi/2]
        while (x > PI) {
            x = sub(x, TWOPI);
        }
        while (x < neg(PI)) {
            x = add(x, TWOPI);
        }
        if(abs(sub(x,HALFPI))<divi(1,100)){
            return fromUInt(1);
        }
        if(abs(sub(x,neg(HALFPI)))<divi(1,100)){
            return neg(fromUInt(1));
        }
        if(abs(sub(x,PI))<divi(1,50)||abs(sub(x,neg(PI)))<divi(1,50)){
            return fromUInt(0);
        }
        if(x<0){
            return neg(sin(neg(x)));
        }
        if(x>=HALFPI){
            return (sin(sub(PI,x)));
        }
        // next line use tylar approximation
        // sin(x) =x - x^3/6 + x^5/120 - x^7/5040 + x^9/362880 - x^11/39916800
        int128 tmp=sub(x,div(pow(x,3),fromUInt(6)));
        tmp=add(tmp,div(pow(x,5),fromUInt(120)));
        tmp=sub(tmp,div(pow(x,7),fromUInt(5040)));
        //tmp=add(tmp,div(pow(x,9),fromUInt(362880)));
        //tmp=sub(tmp,divi(pow(x,11),39916800));
        return tmp;
    }

    function cos(int128 x) internal pure returns (int128) {
        return sin(add(x, HALFPI));
    }
    

}
