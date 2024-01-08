// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeMath.sol";

/**
 * @dev Library for calculating exponential of unsigned 64.64-bit fixed-point numbers
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using Exponential for uint256;
 * }
 * ```
 */
library Exponential {
    using SafeMath for uint256;

    uint256 private constant _MAX_UINT256_64_64 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 private constant _EXP2_OUT_FRACTION_BITS = 64;
    uint256 private constant _EXP2_OUT_INTEGER_BITS = 64;

    uint256 private constant _EXP2_FRACTION_MASK =
        2**(_EXP2_OUT_FRACTION_BITS - 1);
    uint256 private constant _EXP2_IN_MAX_EXPONENT =
        _EXP2_OUT_INTEGER_BITS << _EXP2_OUT_FRACTION_BITS;
    uint256 private constant _EXP2_SCALE =
        2**(_EXP2_OUT_INTEGER_BITS + _EXP2_OUT_FRACTION_BITS - 1);

    // _EXP2_MAGIC_FACTOR_x = 2**(2**(-x)) represented as 128 fraction bits fixed-point number
    uint256 private constant _EXP2_MAGIC_FACTOR_FRACTION_BITS = 128;
    uint256 private constant _EXP2_MAGIC_FACTOR_01 =
        0x16A09E667F3BCC908B2FB1366EA957D3E;
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-too-similar
    // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_02 =
        0x1306FE0A31B7152DE8D5A46305C85EDEC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_03 =
        0x1172B83C7D517ADCDF7C8C50EB14A791F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_04 =
        0x10B5586CF9890F6298B92B71842A98363;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_05 =
        0x1059B0D31585743AE7C548EB68CA417FD;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_06 =
        0x102C9A3E778060EE6F7CACA4F7A29BDE8;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_07 =
        0x10163DA9FB33356D84A66AE336DCDFA3F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_08 =
        0x100B1AFA5ABCBED6129AB13EC11DC9543;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_09 =
        0x10058C86DA1C09EA1FF19D294CF2F679B;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_10 =
        0x1002C605E2E8CEC506D21BFC89A23A00F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_11 =
        0x100162F3904051FA128BCA9C55C31E5DF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_12 =
        0x1000B175EFFDC76BA38E31671CA939725;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_13 =
        0x100058BA01FB9F96D6CACD4B180917C3D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_14 =
        0x10002C5CC37DA9491D0985C348C68E7B3;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_15 =
        0x1000162E525EE054754457D5995292026;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_16 =
        0x10000B17255775C040618BF4A4ADE83FC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_17 =
        0x1000058B91B5BC9AE2EED81E9B7D4CFAB;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_18 =
        0x100002C5C89D5EC6CA4D7C8ACC017B7C9;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_19 =
        0x10000162E43F4F831060E02D839A9D16D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_20 =
        0x100000B1721BCFC99D9F890EA06911763;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_21 =
        0x10000058B90CF1E6D97F9CA14DBCC1628;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_22 =
        0x1000002C5C863B73F016468F6BAC5CA2B;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_23 =
        0x100000162E430E5A18F6119E3C02282A5;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_24 =
        0x1000000B1721835514B86E6D96EFD1BFE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_25 =
        0x100000058B90C0B48C6BE5DF846C5B2EF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_26 =
        0x10000002C5C8601CC6B9E94213C72737A;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_27 =
        0x1000000162E42FFF037DF38AA2B219F06;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_28 =
        0x10000000B17217FBA9C739AA5819F44F9;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_29 =
        0x1000000058B90BFCDEE5ACD3C1CEDC823;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_30 =
        0x100000002C5C85FE31F35A6A30DA1BE50;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_31 =
        0x10000000162E42FF0999CE3541B9FFFCF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_32 =
        0x100000000B17217F80F4EF5AADDA45554;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_33 =
        0x10000000058B90BFBF8479BD5A81B51AD;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_34 =
        0x1000000002C5C85FDF84BD62AE30A74CC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_35 =
        0x100000000162E42FEFB2FED257559BDAA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_36 =
        0x1000000000B17217F7D5A7716BBA4A9AE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_37 =
        0x100000000058B90BFBE9DDBAC5E109CCE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_38 =
        0x10000000002C5C85FDF4B15DE6F17EB0D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_39 =
        0x1000000000162E42FEFA494F1478FDE05;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_40 =
        0x10000000000B17217F7D20CF927C8E94C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_41 =
        0x1000000000058B90BFBE8F71CB4E4B33D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_42 =
        0x100000000002C5C85FDF477B662B26945;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_43 =
        0x10000000000162E42FEFA3AE53369388C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_44 =
        0x100000000000B17217F7D1D351A389D40;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_45 =
        0x10000000000058B90BFBE8E8B2D3D4EDE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_46 =
        0x1000000000002C5C85FDF4741BEA6E77E;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_47 =
        0x100000000000162E42FEFA39FE95583C2;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_48 =
        0x1000000000000B17217F7D1CFB72B45E1;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_49 =
        0x100000000000058B90BFBE8E7CC35C3F0;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_50 =
        0x10000000000002C5C85FDF473E242EA38;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_51 =
        0x1000000000000162E42FEFA39F02B772C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_52 =
        0x10000000000000B17217F7D1CF7D83C1A;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_53 =
        0x1000000000000058B90BFBE8E7BDCBE2E;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_54 =
        0x100000000000002C5C85FDF473DEA871F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_55 =
        0x10000000000000162E42FEFA39EF44D91;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_56 =
        0x100000000000000B17217F7D1CF79E949;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_57 =
        0x10000000000000058B90BFBE8E7BCE544;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_58 =
        0x1000000000000002C5C85FDF473DE6ECA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_59 =
        0x100000000000000162E42FEFA39EF366F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_60 =
        0x1000000000000000B17217F7D1CF79AFA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_61 =
        0x100000000000000058B90BFBE8E7BCD6D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_62 =
        0x10000000000000002C5C85FDF473DE6B2;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_63 =
        0x1000000000000000162E42FEFA39EF358;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_64 =
        0x10000000000000000B17217F7D1CF79AB;

    uint256 private constant _LOG2_OUT_FRACTION_BITS = 64;
    uint256 private constant _LOG2_OUT_INTEGER_BITS = 64;

    uint256 private constant _LOG2_BITSHIFT_64 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 1;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_32 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 2;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_16 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 3;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_08 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 4;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_04 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 5;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_02 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 6;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_01 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 7;

    uint256 private constant _LOG2_FRACTION_MASK =
        1 << (_LOG2_OUT_FRACTION_BITS - 1);
    uint256 private constant _LOG2_IN_MAX_ARG =
        1 << (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS);

    uint256 private constant _LOG2_THRESHOLD_64 = 1 << _LOG2_BITSHIFT_64;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_32 = 1 << _LOG2_BITSHIFT_32;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_16 = 1 << _LOG2_BITSHIFT_16;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_08 = 1 << _LOG2_BITSHIFT_08;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_04 = 1 << _LOG2_BITSHIFT_04;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_02 = 1 << _LOG2_BITSHIFT_02;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_01 = 1 << _LOG2_BITSHIFT_01;

    /**
     * @dev Returns the base 2 exponential of self, reverts if overflow
     *
     * @param self unsigned 6.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function expBase2(uint256 self) internal pure returns (uint256) {
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_FRACTION_MASK == 0x8000000000000000,
            "Exponential: fraction mask"
        );
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_IN_MAX_EXPONENT == 0x400000000000000000,
            "Exponential: max exponent"
        );
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_SCALE == 0x80000000000000000000000000000000,
            "Exponential: scale"
        );

        require(self < _EXP2_IN_MAX_EXPONENT, "Exponential: overflow");

        uint256[_EXP2_OUT_FRACTION_BITS] memory magicFactors =
            [
                _EXP2_MAGIC_FACTOR_01,
                _EXP2_MAGIC_FACTOR_02,
                _EXP2_MAGIC_FACTOR_03,
                _EXP2_MAGIC_FACTOR_04,
                _EXP2_MAGIC_FACTOR_05,
                _EXP2_MAGIC_FACTOR_06,
                _EXP2_MAGIC_FACTOR_07,
                _EXP2_MAGIC_FACTOR_08,
                _EXP2_MAGIC_FACTOR_09,
                _EXP2_MAGIC_FACTOR_10,
                _EXP2_MAGIC_FACTOR_11,
                _EXP2_MAGIC_FACTOR_12,
                _EXP2_MAGIC_FACTOR_13,
                _EXP2_MAGIC_FACTOR_14,
                _EXP2_MAGIC_FACTOR_15,
                _EXP2_MAGIC_FACTOR_16,
                _EXP2_MAGIC_FACTOR_17,
                _EXP2_MAGIC_FACTOR_18,
                _EXP2_MAGIC_FACTOR_19,
                _EXP2_MAGIC_FACTOR_20,
                _EXP2_MAGIC_FACTOR_21,
                _EXP2_MAGIC_FACTOR_22,
                _EXP2_MAGIC_FACTOR_23,
                _EXP2_MAGIC_FACTOR_24,
                _EXP2_MAGIC_FACTOR_25,
                _EXP2_MAGIC_FACTOR_26,
                _EXP2_MAGIC_FACTOR_27,
                _EXP2_MAGIC_FACTOR_28,
                _EXP2_MAGIC_FACTOR_29,
                _EXP2_MAGIC_FACTOR_30,
                _EXP2_MAGIC_FACTOR_31,
                _EXP2_MAGIC_FACTOR_32,
                _EXP2_MAGIC_FACTOR_33,
                _EXP2_MAGIC_FACTOR_34,
                _EXP2_MAGIC_FACTOR_35,
                _EXP2_MAGIC_FACTOR_36,
                _EXP2_MAGIC_FACTOR_37,
                _EXP2_MAGIC_FACTOR_38,
                _EXP2_MAGIC_FACTOR_39,
                _EXP2_MAGIC_FACTOR_40,
                _EXP2_MAGIC_FACTOR_41,
                _EXP2_MAGIC_FACTOR_42,
                _EXP2_MAGIC_FACTOR_43,
                _EXP2_MAGIC_FACTOR_44,
                _EXP2_MAGIC_FACTOR_45,
                _EXP2_MAGIC_FACTOR_46,
                _EXP2_MAGIC_FACTOR_47,
                _EXP2_MAGIC_FACTOR_48,
                _EXP2_MAGIC_FACTOR_49,
                _EXP2_MAGIC_FACTOR_50,
                _EXP2_MAGIC_FACTOR_51,
                _EXP2_MAGIC_FACTOR_52,
                _EXP2_MAGIC_FACTOR_53,
                _EXP2_MAGIC_FACTOR_54,
                _EXP2_MAGIC_FACTOR_55,
                _EXP2_MAGIC_FACTOR_56,
                _EXP2_MAGIC_FACTOR_57,
                _EXP2_MAGIC_FACTOR_58,
                _EXP2_MAGIC_FACTOR_59,
                _EXP2_MAGIC_FACTOR_60,
                _EXP2_MAGIC_FACTOR_61,
                _EXP2_MAGIC_FACTOR_62,
                _EXP2_MAGIC_FACTOR_63,
                _EXP2_MAGIC_FACTOR_64
            ];

        uint256 mask = _EXP2_FRACTION_MASK;
        uint256 result = _EXP2_SCALE;

        for (uint256 i = 0; i < _EXP2_OUT_FRACTION_BITS; i++) {
            if ((self & mask) > 0) {
                result =
                    (result * magicFactors[i]) >>
                    _EXP2_MAGIC_FACTOR_FRACTION_BITS;
            }

            mask >>= 1;
        }

        require(mask == 0, "Exponential: unexpected mask");

        result >>=
            _EXP2_OUT_INTEGER_BITS -
            1 -
            (self >> _EXP2_OUT_FRACTION_BITS);
        require(result <= _MAX_UINT256_64_64, "Exponential: exceed");

        return result;
    }

    /**
     * @dev Returns the base 2 logarithm of self, reverts if self <= 0
     *
     * @param self unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function logBase2(uint256 self) internal pure returns (uint256) {
        require(_LOG2_BITSHIFT_64 == 64, "Exponential: bitshift 64");
        require(_LOG2_BITSHIFT_32 == 32, "Exponential: bitshift 32");
        require(_LOG2_BITSHIFT_16 == 16, "Exponential: bitshift 16");
        require(_LOG2_BITSHIFT_08 == 8, "Exponential: bitshift 8");
        require(_LOG2_BITSHIFT_04 == 4, "Exponential: bitshift 4");
        require(_LOG2_BITSHIFT_02 == 2, "Exponential: bitshift 2");
        require(_LOG2_BITSHIFT_01 == 1, "Exponential: bitshift 1");

        // slither-disable-next-line too-many-digits
        require(
            _LOG2_FRACTION_MASK == 0x8000000000000000,
            "Exponential: fraction mask"
        );
        // slither-disable-next-line too-many-digits
        require(
            _LOG2_IN_MAX_ARG == 0x100000000000000000000000000000000,
            "Exponential: max arg"
        );
        // slither-disable-next-line too-many-digits
        require(
            _LOG2_THRESHOLD_64 == 0x10000000000000000,
            "Exponential: threshold 64"
        );
        // slither-disable-next-line too-many-digits
        require(_LOG2_THRESHOLD_32 == 0x100000000, "Exponential: threshold 32");
        require(_LOG2_THRESHOLD_16 == 0x10000, "Exponential: threshold 16");
        require(_LOG2_THRESHOLD_08 == 0x100, "Exponential: threshold 8");
        require(_LOG2_THRESHOLD_04 == 0x10, "Exponential: threshold 4");
        require(_LOG2_THRESHOLD_02 == 0x4, "Exponential: threshold 2");
        require(_LOG2_THRESHOLD_01 == 0x2, "Exponential: threshold 1");

        require(self > 0, "Exponential: zero");
        require(self < _LOG2_IN_MAX_ARG, "Exponential: overflow");

        uint256 leftover = self;
        uint256 intResult = 0;

        if (leftover >= _LOG2_THRESHOLD_64) {
            leftover >>= _LOG2_BITSHIFT_64;
            intResult += _LOG2_BITSHIFT_64;
        }

        if (leftover >= _LOG2_THRESHOLD_32) {
            leftover >>= _LOG2_BITSHIFT_32;
            intResult += _LOG2_BITSHIFT_32;
        }

        if (leftover >= _LOG2_THRESHOLD_16) {
            leftover >>= _LOG2_BITSHIFT_16;
            intResult += _LOG2_BITSHIFT_16;
        }

        if (leftover >= _LOG2_THRESHOLD_08) {
            leftover >>= _LOG2_BITSHIFT_08;
            intResult += _LOG2_BITSHIFT_08;
        }

        if (leftover >= _LOG2_THRESHOLD_04) {
            leftover >>= _LOG2_BITSHIFT_04;
            intResult += _LOG2_BITSHIFT_04;
        }

        if (leftover >= _LOG2_THRESHOLD_02) {
            leftover >>= _LOG2_BITSHIFT_02;
            intResult += _LOG2_BITSHIFT_02;
        }

        if (leftover >= _LOG2_THRESHOLD_01) {
            intResult += _LOG2_BITSHIFT_01;
        }

        uint256 result =
            (intResult - _LOG2_OUT_FRACTION_BITS) << _LOG2_OUT_FRACTION_BITS;
        uint256 scalex =
            self <<
                (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS - 1).sub(
                    intResult
                );
        for (uint256 mask = _LOG2_FRACTION_MASK; mask > 0; mask >>= 1) {
            scalex *= scalex;
            uint256 bit =
                scalex >>
                    ((_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) *
                        2 -
                        1);
            scalex >>=
                _LOG2_OUT_INTEGER_BITS +
                _LOG2_OUT_FRACTION_BITS -
                1 +
                bit;
            result += mask * bit;
        }

        return result;
    }
}
