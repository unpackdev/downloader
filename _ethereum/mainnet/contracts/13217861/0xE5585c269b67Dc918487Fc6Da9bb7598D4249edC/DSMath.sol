// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable
function _add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function _sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function _mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function _min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function _max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function _imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function _imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;
uint256 constant QUA = 10**4;

//rounds to zero if x*y < WAD / 2
function _wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function _rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function _wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function _rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function _rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = _rmul(x, x);

        if (n % 2 != 0) {
            z = _rmul(z, x);
        }
    }
}

//rounds to zero if x*y < QUA / 2
function _qmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), QUA / 2) / QUA;
}

//rounds to zero if x*y < QUA / 2
function _qdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, QUA), y / 2) / y;
}
