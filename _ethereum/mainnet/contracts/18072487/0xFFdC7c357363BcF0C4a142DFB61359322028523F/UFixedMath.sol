// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Math} from "Math.sol";

type UFixed is uint256;

using {
    addUFixed as +,
    subUFixed as -,
    mulUFixed as *,
    divUFixed as /,
    gtUFixed as >,
    gteUFixed as >=,
    ltUFixed as <,
    lteUFixed as <=,
    eqUFixed as ==
}
    for UFixed global;

function addUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    return UFixed.wrap(UFixed.unwrap(a) + UFixed.unwrap(b));
}

function subUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    require(a >= b, "ERROR:UFM-010:NEGATIVE_RESULT");

    return UFixed.wrap(UFixed.unwrap(a) - UFixed.unwrap(b));
}

function mulUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    return UFixed.wrap(Math.mulDiv(UFixed.unwrap(a), UFixed.unwrap(b), 10 ** 18));
}

function divUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    require(UFixed.unwrap(b) > 0, "ERROR:UFM-020:DIVISOR_ZERO");

    return UFixed.wrap(
        Math.mulDiv(
            UFixed.unwrap(a), 
            10 ** 18,
            UFixed.unwrap(b)));
}

function gtUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) > UFixed.unwrap(b);
}

function gteUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) >= UFixed.unwrap(b);
}

function ltUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) < UFixed.unwrap(b);
}

function lteUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) <= UFixed.unwrap(b);
}

function eqUFixed(UFixed a, UFixed b) pure returns(bool isEqual) {
    return UFixed.unwrap(a) == UFixed.unwrap(b);
}

function gtz(UFixed a) pure returns(bool isZero) {
    return UFixed.unwrap(a) > 0;
}

function eqz(UFixed a) pure returns(bool isZero) {
    return UFixed.unwrap(a) == 0;
}

function delta(UFixed a, UFixed b) pure returns(UFixed) {
    if(a > b) {
        return a - b;
    }

    return b - a;
}

contract UFixedType {

    enum Rounding {
        Down, // floor(value)
        Up, // = ceil(value)
        HalfUp // = floor(value + 0.5)
    }

    int8 public constant EXP = 18;
    uint256 public constant MULTIPLIER = 10 ** uint256(int256(EXP));
    uint256 public constant MULTIPLIER_HALF = MULTIPLIER / 2;
    
    Rounding public constant ROUNDING_DEFAULT = Rounding.HalfUp;

    function decimals() public pure returns(uint256) {
        return uint8(EXP);
    }

    function itof(uint256 a)
        public
        pure
        returns(UFixed)
    {
        return UFixed.wrap(a * MULTIPLIER);
    }

    function itof(uint256 a, int8 exp)
        public
        pure
        returns(UFixed)
    {
        require(EXP + exp >= 0, "ERROR:FM-010:EXPONENT_TOO_SMALL");
        require(EXP + exp <= 2 * EXP, "ERROR:FM-011:EXPONENT_TOO_LARGE");

        return UFixed.wrap(a * 10 ** uint8(EXP + exp));
    }

    function ftoi(UFixed a)
        public
        pure
        returns(uint256)
    {
        return ftoi(a, ROUNDING_DEFAULT);
    }

    function ftoi(UFixed a, Rounding rounding)
        public
        pure
        returns(uint256)
    {
        if(rounding == Rounding.HalfUp) {
            return Math.mulDiv(UFixed.unwrap(a) + MULTIPLIER_HALF, 1, MULTIPLIER, Math.Rounding.Down);
        } else if(rounding == Rounding.Down) {
            return Math.mulDiv(UFixed.unwrap(a), 1, MULTIPLIER, Math.Rounding.Down);
        } else {
            return Math.mulDiv(UFixed.unwrap(a), 1, MULTIPLIER, Math.Rounding.Up);
        }
    }
}
