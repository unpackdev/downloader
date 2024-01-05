// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Const.sol";

contract Num is Const {

    function toi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function floor(uint a)
        internal pure
        returns (uint)
    {
        return toi(a) * BONE;
    }

    function add(uint a, uint b)
        internal pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(uint a, uint b)
        internal pure
        returns (uint c)
    {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, "SUB_UNDERFLOW");
    }

    function subSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint a, uint b)
        internal pure
        returns (uint c)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "MUL_OVERFLOW");
        c = c1 / BONE;
    }

    function div(uint a, uint b)
        internal pure
        returns (uint c)
    {
        require(b != 0, "DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "DIV_INTERNAL"); // mul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "DIV_INTERNAL"); //  add require
        c = c1 / b;
    }

    // DSMath.wpow
    function powi(uint a, uint n)
        internal pure
        returns (uint z)
    {
        z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_POW_BASE, "POW_BASE_TOO_LOW");
        require(base <= MAX_POW_BASE, "POW_BASE_TOO_HIGH");

        uint whole  = floor(exp);
        uint remain = sub(exp, whole);

        uint wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = powApprox(base, remain, POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint sum)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = subSign(base, BONE);
        uint term = BONE;
        sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = subSign(a, sub(bigK, BONE));
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
    }

    function min(uint first, uint second)
        internal pure
        returns (uint)
    {
        if(first < second) {
            return first;
        }
        return second;
    }
}
