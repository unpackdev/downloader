// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @title An inteerface of a factory of custom ERC20 tokens used in the bridge
interface IWrappedERC20Factory {

    /// @notice Creates a new ERC 20 token to be used in the bridge
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token on the original chain
    /// @param name The name of the new token
    /// @param symbol The symbol of the new token
    /// @param decimals The number of decimals of the new token
    /// @return The address of a new token
    function createERC20Token(
        string memory originalChain,
        address originalToken,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address bridge
    ) external returns(address);

    /// @notice Creates a new ERC721 token to be used in the bridge
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token on the original chain
    /// @param name The name of the new token
    /// @param symbol The symbol of the new token
    /// @return The address of a new token
    function createERC721Token(
        string memory originalChain,
        address originalToken,
        string memory name,
        string memory symbol,
        address bridge
    ) external returns(address);

    /// @notice Creates a new ERC 1155 token to be used in the bridge
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token on the original chain
    /// @param tokenUri The URI of the token
    /// @return The address of a new token
    function createERC1155Token(
        string memory originalChain,
        address originalToken,
        string memory tokenUri,
        address bridge
    ) external returns(address);

    /// @dev Event gets emmited each time a new ERC20 token is created
    event CreateERC20Token(
        string originalChain,
        address originalToken,
        string name, 
        address indexed token
    );

    /// @dev Event gets emmited each time a new ERC721 token is created
    event CreateERC721Token(
        string originalChain,
        address originalToken,
        string name, 
        address indexed token
    );

    /// @dev Event gets emmited each time a new ERC1155 token is created
    event CreateERC1155Token(
        string originalChain,
        address originalToken,
        string tokenUri, 
        address indexed token
    );
}
