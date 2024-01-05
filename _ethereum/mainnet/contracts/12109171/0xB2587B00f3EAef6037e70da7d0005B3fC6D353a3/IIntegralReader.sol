// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IIntegralReader {
    struct Parameters {
        int256[] bidExponents;
        int256[] bidQs;
        int256[] askExponents;
        int256[] askQs;
    }

    function getPairParameters(address pair)
        external
        view
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint112 reference0,
            uint112 reference1,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee,
            uint32 pairEpoch,
            uint32 oracleEpoch,
            int256 price,
            Parameters memory parameters
        );
}
