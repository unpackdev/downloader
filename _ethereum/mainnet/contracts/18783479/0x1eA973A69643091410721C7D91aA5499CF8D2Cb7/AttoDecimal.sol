// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library AttoDecimal {
    struct Instance {
        uint256 mantissa;
    }

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant ONE_TENTH_MANTISSA = ONE_MANTISSA / 10;
    uint256 internal constant HALF_MANTISSA = ONE_MANTISSA / 2;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;
    uint256 internal constant MAX_INTEGER = type(uint256).max / ONE_MANTISSA;

    function maximum() internal pure returns (Instance memory) {
        return Instance({mantissa: type(uint256).max});
    }

    function zero() internal pure returns (Instance memory) {
        return Instance({mantissa: 0});
    }

    function one() internal pure returns (Instance memory) {
        return Instance({mantissa: ONE_MANTISSA});
    }

    function convert(uint256 integer) internal pure returns (Instance memory) {
        return Instance({mantissa: integer * ONE_MANTISSA});
    }

    function compare(Instance memory a, Instance memory b) internal pure returns (int8) {
        if (a.mantissa < b.mantissa) return -1;
        return int8(a.mantissa > b.mantissa ? 1 : 0);
    }

    function compare(Instance memory a, uint256 b) internal pure returns (int8) {
        return compare(a, convert(b));
    }

    function add(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa + b.mantissa});
    }

    function add(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa + b * ONE_MANTISSA});
    }

    function sub(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa - b.mantissa});
    }

    function sub(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa - b * ONE_MANTISSA});
    }

    function sub(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * ONE_MANTISSA - b.mantissa});
    }

    function mul(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * b.mantissa / ONE_MANTISSA});
    }

    function mul(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * b});
    }

    function div(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa * ONE_MANTISSA / b.mantissa});
    }

    function div(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa / b});
    }

    function div(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * SQUARED_ONE_MANTISSA / b.mantissa});
    }

    function div(uint256 a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a * ONE_MANTISSA / b});
    }

    function idiv(Instance memory a, Instance memory b) internal pure returns (uint256) {
        return a.mantissa / b.mantissa;
    }

    function idiv(Instance memory a, uint256 b) internal pure returns (uint256) {
        return a.mantissa / (b * ONE_MANTISSA);
    }

    function idiv(uint256 a, Instance memory b) internal pure returns (uint256) {
        return a * ONE_MANTISSA / b.mantissa;
    }

    function mod(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa % b.mantissa});
    }

    function mod(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa % (b * ONE_MANTISSA)});
    }

    function mod(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        if (a > MAX_INTEGER) return Instance({mantissa: a % b.mantissa * ONE_MANTISSA % b.mantissa});
        return Instance({mantissa: a * ONE_MANTISSA % b.mantissa});
    }

    function floor(Instance memory a) internal pure returns (uint256) {
        return a.mantissa / ONE_MANTISSA;
    }

    function ceil(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + (a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function round(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + ((a.mantissa / ONE_TENTH_MANTISSA) % 10 >= 5 ? 1 : 0);
    }

    function eq(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa == b.mantissa;
    }

    function eq(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa == b * ONE_MANTISSA;
    }

    function gt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa > b.mantissa;
    }

    function gt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa > b * ONE_MANTISSA;
    }

    function gte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa >= b.mantissa;
    }

    function gte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa >= b * ONE_MANTISSA;
    }

    function lt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa < b.mantissa;
    }

    function lt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa < b * ONE_MANTISSA;
    }

    function lte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function lte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa <= b * ONE_MANTISSA;
    }

    function isInteger(Instance memory a) internal pure returns (bool) {
        return a.mantissa % ONE_MANTISSA == 0;
    }

    function isPositive(Instance memory a) internal pure returns (bool) {
        return a.mantissa > 0;
    }

    function isZero(Instance memory a) internal pure returns (bool) {
        return a.mantissa == 0;
    }

    function sum(Instance[] memory array) internal pure returns (Instance memory result) {
        uint256 length = array.length;
        for (uint256 index = 0; index < length; index++) result = add(result, array[index]);
    }

    function toTuple(Instance memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}
