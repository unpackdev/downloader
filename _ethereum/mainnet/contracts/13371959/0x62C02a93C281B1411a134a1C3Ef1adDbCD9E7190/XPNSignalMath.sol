// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

library XPNSignalMath {
    /*
     * assume solidity 0.8.0 over/under flow check
     * will mainly use L1 space aka taxicab geometry
     */

    int256 public constant ONE = 1e18;

    // @notice normalize array
    // @param x array
    // @return scaled array x with size = ONE
    function normalize(int256[] memory x)
        internal
        pure
        returns (int256[] memory out_array)
    {
        out_array = new int256[](x.length);
        int256 size = l1Norm(x);
        if (size == 0) {
            return x;
        }
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = (x[i] * ONE) / (size);
        }
    }

    // @notice element wise addition
    // @param x array
    // @param y array
    // @return int256 array of x elementwise add by y
    function elementWiseAdd(int256[] memory x, int256[] memory y)
        internal
        pure
        returns (int256[] memory out_array)
    {
        require(x.length == y.length, "XPNSignalMath: array size mismatch");
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = (x[i] + y[i]);
        }
    }

    // @notice element wise subtraction
    // @param x array
    // @param y array
    // @return int256 array of x elementwise subtract by y
    function elementWiseSub(int256[] memory x, int256[] memory y)
        internal
        pure
        returns (int256[] memory out_array)
    {
        require(x.length == y.length, "XPNSignalMath: array size mismatch");
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = (x[i] - y[i]);
        }
    }

    // @notice element wise multipication
    // @param x array
    // @param y array
    // @return int256 array of x elementwise multiply by y
    function elementWiseMul(int256[] memory x, int256[] memory y)
        internal
        pure
        returns (int256[] memory out_array)
    {
        require(x.length == y.length, "XPNSignalMath: array size mismatch");
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = ((x[i] * y[i]) / ONE);
        }
    }

    // @notice element wise division
    // @param x array
    // @param y array
    // @return int256 array of x elementwise divided by y
    function elementWiseDiv(int256[] memory x, int256[] memory y)
        internal
        pure
        returns (int256[] memory out_array)
    {
        require(x.length == y.length, "XPNSignalMath: array size mismatch");
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = ((x[i] * ONE) / y[i]);
        }
    }

    // @notice abs of vector
    // @param x int256 array input
    // @return int256 array abs of vector x
    function vectorAbs(int256[] memory x)
        internal
        pure
        returns (int256[] memory out_array)
    {
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = abs(x[i]);
        }
    }

    // @notice scale vector x by a factor
    // @param x int256 array input
    // @param scaleFactor int256 scale factor
    // @return x scaled by scaleFactor
    function vectorScale(int256[] memory x, int256 scaleFactor)
        internal
        pure
        returns (int256[] memory out_array)
    {
        out_array = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            out_array[i] = (x[i] * scaleFactor) / ONE;
        }
    }

    // @notice abs
    // @param x int256 input
    // @return abs x
    function abs(int256 x) internal pure returns (int256) {
        /* 
            abslute value of input
        */
        return x >= 0 ? x : -x;
    }

    // @notice sum all element
    // @param x int256 input array
    // @return sum of elements in x
    function sum(int256[] memory x) internal pure returns (int256 output) {
        output = 0;
        for (uint256 i = 0; i < x.length; i++) {
            output = output + x[i];
        }
    }

    // @notice L1 norm of vector.
    function l1Norm(int256[] memory x) internal pure returns (int256 output) {
        output = sum(vectorAbs(x));
    }
}
