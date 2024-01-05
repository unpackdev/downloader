// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'IIntegralReader.sol';
import 'IIntegralPair.sol';
import 'IIntegralOracle.sol';

contract IntegralReader is IIntegralReader {
    function isContract(address addressToCheck) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addressToCheck)
        }
        return size > 0;
    }

    function getPairParameters(address pair)
        external
        view
        override
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
        )
    {
        exists = isContract(pair);
        if (exists) {
            (reserve0, reserve1, ) = IIntegralPair(pair).getReserves();
            (reference0, reference1, pairEpoch) = IIntegralPair(pair).getReferences();
            mintFee = IIntegralPair(pair).mintFee();
            burnFee = IIntegralPair(pair).burnFee();
            swapFee = IIntegralPair(pair).swapFee();
            address oracle = IIntegralPair(pair).oracle();
            oracleEpoch = IIntegralOracle(oracle).epoch();
            if (oracleEpoch != pairEpoch) {
                reference0 = reserve0;
                reference1 = reserve1;
            }
            price = IIntegralOracle(oracle).price();
            {
                (
                    int256[] memory bidExponents,
                    int256[] memory bidQs,
                    int256[] memory askExponents,
                    int256[] memory askQs
                ) = IIntegralOracle(oracle).getParameters();
                parameters = Parameters(bidExponents, bidQs, askExponents, askQs);
            }
        }
    }
}
