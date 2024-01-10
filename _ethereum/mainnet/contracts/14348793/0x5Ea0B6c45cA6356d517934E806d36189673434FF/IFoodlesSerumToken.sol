// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IFoodlesSerumToken {

    /**
     * Burn serum
     * @notice This can only be called by the Mutated Foodles contract.
     */
    function burnSerum(address from, uint256 numTokens) external;

}
