// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library BasisPoints {
    function check(uint16 basisPoint) internal pure returns (bool) {
        return (basisPoint > 0 && basisPoint <= 10000);
    }

    function calculeAmount(uint16 basisPoint, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return ((amount * basisPoint) / 10000);
    }
}
