// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface ICirculatingSupply {
    /**
     * Returns the circulating supply (total supply minus tokens held by operators)
     */
    function circulatingSupply() external view returns (uint256);
}
