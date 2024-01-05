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

import "./ABDKMathQuad.sol";
import "./Const.sol";

contract NumExtra is Const {
    function toIntMultiplied(bytes16 value, uint256 bone)
    internal pure
    returns(int256)
    {
        return ABDKMathQuad.toInt(ABDKMathQuad.mul(value, ABDKMathQuad.fromUInt(bone)));
    }

    function fromIntMultiplied(int256 value, uint256 bone)
    internal pure
    returns(bytes16)
    {
        return ABDKMathQuad.div(ABDKMathQuad.fromInt(value), ABDKMathQuad.fromUInt(bone));
    }

    function ln(int256 x) public pure returns(int256) {
        return toIntMultiplied(
            ABDKMathQuad.ln(fromIntMultiplied(x, BONE)),
            BONE
        );
    }

    function sqrt(int256 x) public pure returns(int256) {
        return toIntMultiplied(
            ABDKMathQuad.sqrt(fromIntMultiplied(x, BONE)),
            BONE
        );
    }

    function powi(bytes16 a, uint n)
    internal pure
    returns (bytes16)
    {
        bytes16 z = n % 2 != 0 ? a : ABDKMathQuad.fromInt(1);

        for (n /= 2; n != 0; n /= 2) {
            a = ABDKMathQuad.mul(a, a);

            if (n % 2 != 0) {
                z = ABDKMathQuad.mul(z, a);
            }
        }
        return z;
    }

    // https://stackoverflow.com/questions/2328258/cumulative-normal-distribution-function-in-c-c/23119456#23119456
    function ncdf(int x)
    public pure
    returns (int256)
    {
        bytes16 xq = fromIntMultiplied(x, BONE);

        bytes16 z = ABDKMathQuad.abs(xq);
        bytes16 c = 0x00000000000000000000000000000000;

        if(ABDKMathQuad.cmp(z, ABDKMathQuad.fromUInt(37)) == int8(-1) || ABDKMathQuad.eq(z, ABDKMathQuad.fromUInt(37)) )
        {
            bytes16 e = ABDKMathQuad.exp(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(ABDKMathQuad.neg(z), z),
                    ABDKMathQuad.fromUInt(2)
                )
            );

            if(ABDKMathQuad.cmp(z, fromIntMultiplied(707106781186547, 10**14)) == int8(-1))
            {
                c = one(z, e);
            } else {
                c = two(z, e);
            }
        }
        c = (ABDKMathQuad.sign(xq) == int8(-1) || ABDKMathQuad.eq(xq, 0)) ? c : ABDKMathQuad.sub(ABDKMathQuad.fromUInt(1), c);
        return toIntMultiplied(c, BONE);
    }

    function one(bytes16 z, bytes16 e)
    internal pure
    returns (bytes16)
    {
        bytes16 n = addm(
            addm(
                addm(
                    addm(
                        addm(
                            addm(fromIntMultiplied(352624965998911, 10**16), z, fromIntMultiplied(700383064443688, 10**15)),
                            z, fromIntMultiplied(637396220353165, 10**14)),
                        z, fromIntMultiplied(33912866078383, 10**12)),
                    z, fromIntMultiplied(112079291497871, 10**12)),
                z, fromIntMultiplied(221213596169931, 10**12)),
            z, fromIntMultiplied(220206867912376, 10**12)
        );
        bytes16 d = addm(
            addm(
                addm(
                    addm(
                        addm(
                            addm(
                                addm(fromIntMultiplied(883883476483184, 10**16), z, fromIntMultiplied(175566716318264, 10**14)),
                                z, fromIntMultiplied(16064177579207, 10**12)),
                            z, fromIntMultiplied(867807322029461, 10**13)),
                        z, fromIntMultiplied(296564248779674, 10**12)),
                    z, fromIntMultiplied(637333633378831, 10**12)),
                z, fromIntMultiplied(793826512519948, 10**12)),
            z, fromIntMultiplied(440413735824752, 10**12));

        return ABDKMathQuad.div(ABDKMathQuad.mul(e, n), d);
    }

    function two(bytes16 z, bytes16 e)
    internal pure
    returns (bytes16)
    {
        bytes16 f = addr(z, ABDKMathQuad.fromUInt(13), ABDKMathQuad.fromUInt(20));
        f =  addr(z, ABDKMathQuad.fromUInt(4), f);
        f =  addr(z, ABDKMathQuad.fromUInt(3), f);
        f =  addr(z, ABDKMathQuad.fromUInt(2), f);
        f =  addr(z, ABDKMathQuad.fromUInt(1), f);

        return ABDKMathQuad.div(e, ABDKMathQuad.div(fromIntMultiplied(250662827463, 10**11), f)); // sqrt(4.0*acos(0.0))
    }

    function addm(bytes16 a, bytes16 b, bytes16 c)
    internal pure
    returns (bytes16)
    {
        return ABDKMathQuad.add(ABDKMathQuad.mul(a, b), c);
    }

    function addr(bytes16 a, bytes16 b, bytes16 c)
    internal pure
    returns (bytes16)
    {
        return ABDKMathQuad.add(a, ABDKMathQuad.div(b, c));
    }
}
