// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenFactoryERC1155 {
    /**
     * Mints tokens to a specific address with a particular "option".
     * This should be callable only by the account who has the minter role.
     * @param optionId the option id (default: 0)
     * @param toAddress address of the future owner of the tokens
     * @param amount amount of the option to mint
     */
    function mint(uint256 optionId, address toAddress, uint256 amount) external;

    /**
     * Returns a URL specifying some metadata about the option.
     */
    function uri(uint256 optionId) external view returns (string memory);
}
