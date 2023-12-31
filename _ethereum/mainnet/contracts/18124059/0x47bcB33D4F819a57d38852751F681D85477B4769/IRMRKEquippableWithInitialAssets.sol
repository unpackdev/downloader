// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

interface IRMRKEquippableWithInitialAssets {
    /**
     * @notice Used to mint the desired number of tokens to the specified address.
     * @dev The `data` value of the `_safeMint` method is set to an empty value.
     * @dev Can only be called while the open sale is open.
     * @param to Address to which to mint the token
     * @param numToMint Number of tokens to mint
     * @return The ID of the first token to be minted in the current minting cycle
     */
    function mint(address to, uint256 numToMint) external returns (uint256);
}
