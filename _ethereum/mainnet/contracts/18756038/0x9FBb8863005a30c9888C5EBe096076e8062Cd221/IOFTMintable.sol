// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IOFTMintable {
    /**
     * @notice Mint tokens.
     * @dev Only callable by address with minter role.
     * @param _account Address to mint tokens to.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount) external;

    /**
     * @notice Set minter role.
     * @param _minter address for adding or removing minter role.
     * @param _isMinter boolean value for defining minter role.
     */
    function setMinter(address _minter, bool _isMinter) external;
}
