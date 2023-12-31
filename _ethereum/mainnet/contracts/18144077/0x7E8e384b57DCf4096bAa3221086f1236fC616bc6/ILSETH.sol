// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILSETH {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of Underlying connected to protocol.
     */
    function totalUnderlyingSupply() external view returns (uint256);
}
