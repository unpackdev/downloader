// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ITwapReader.sol";
import "./ITwapPair.sol";
import "./ITwapOracle.sol";

contract TwapReader is ITwapReader {
    function isContract(address addressToCheck) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addressToCheck)
        }
        return size > 0;
    }

    function getPairParameters(address pairAddress)
        external
        view
        override
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint256 price,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee
        )
    {
        exists = isContract(pairAddress);
        if (exists) {
            ITwapPair pair = ITwapPair(pairAddress);
            (reserve0, reserve1) = pair.getReserves();
            price = ITwapOracle(pair.oracle()).getSpotPrice();
            mintFee = pair.mintFee();
            burnFee = pair.burnFee();
            swapFee = pair.swapFee();
        }
    }
}
