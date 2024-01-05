pragma solidity >=0.6.0 <0.9.0;

//SPDX-License-Identifier: MIT

library CostUtils {
    function getMintCost(uint256 jNumber, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        require(jNumber >= 0);
        require(jNumber < 100);
        return (((jNumber * 110)) * (uint256(10)**decimals)) / 100;
    }

    function getMintFee(uint256 jNumber, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 cost = getMintCost(jNumber, decimals);
        return cost / 11;
    }

    function getBurnValue(uint256 jNumber, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        require(jNumber >= 0);
        require(jNumber < 100);
        return jNumber * (uint256(10)**decimals);
    }
}
