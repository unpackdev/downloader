//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IERC1155SupplyUpgradeable {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}
