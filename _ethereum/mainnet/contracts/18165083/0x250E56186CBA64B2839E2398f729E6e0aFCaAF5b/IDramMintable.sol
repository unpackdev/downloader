// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDramMintable {
    /**
     * @dev Happens when an address wants to mint over its cap
     * or when subtracting mint cap is not possible arithmetically
     */
    error InsufficientMintCapError();

    /**
     * @notice Happens when the mint cap of an `account` changes.
     * @param account Address that it's mint cap is changed
     * @param operator The operator who changes the mint cap
     * @param amount New minting cap
     */
    event MintCapChanged(
        address indexed account,
        address indexed operator,
        uint256 amount
    );

    /**
     * Returns mint cap of an address.
     * @param operator The address whit a mint cap
     */
    function mintCap(address operator) external view returns (uint256);
}
