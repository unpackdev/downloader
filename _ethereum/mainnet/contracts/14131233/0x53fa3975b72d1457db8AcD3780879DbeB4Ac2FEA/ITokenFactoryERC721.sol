// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenFactoryERC721 {
    /**
     * Mints tokens to a specific address with a particular "option".
     * This should be callable only by the account who has the minter role.
     * @param optionId the option id (default: 0)
     * @param toAddress address of the future owner of the tokens
     */
    function mint(uint256 optionId, address toAddress) external;

    /**
     * Returns a URL specifying some metadata about the option.
     */
    function uri(uint256 optionId) external view returns (string memory);
}
