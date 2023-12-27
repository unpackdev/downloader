// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./BasicMintConfiguration.sol";
import "./IConfigurable.sol";

interface IBasicMintModuleEvents {
    /// @notice Emitted when a contract's basic mint configuration is updated.
    /// @param _contract The address of the contract being configured.
    /// @param _config The new configuration.
    event ConfigurationUpdated(address indexed _contract, BasicMintConfiguration _config);
}

interface IBasicMintModule is IConfigurable, IBasicMintModuleEvents {
    /// @notice Retrieves the basic minting configuration for a contract.
    /// @param _contract The address of the contract.
    /// @return The current minting configuration.
    function configuration(address _contract) external view returns (BasicMintConfiguration memory);

    /// @notice Mints tokens for a NFT contract to a recipient.
    /// @dev Reverts if the mint does not work in the current configuration.
    /// @param _contract The address of the contract to mint for.
    /// @param _to The recipient of the tokens.
    /// @param _referrer The referrer of this mint, or the zero address if none.
    /// @param _quantity The quantity of tokens to mint.
    function mint(address _contract, address _to, address _referrer, uint256 _quantity) external payable;

    /// @notice Mints tokens for a NFT contract to a recipient.
    /// @dev Reverts if the mint does not work in the current configuration.
    /// This function is preferred over `mint` because the four byte signature is 0x00000000 which is cheaper to call.
    /// The implementation is identical to `mint`.
    /// @param _contract The address of the contract to mint for.
    /// @param _to The recipient of the tokens.
    /// @param _referrer The referrer of this mint, or the zero address if none.
    /// @param _quantity The quantity of tokens to mint.
    function mint_efficient_7e80c46e(address _contract, address _to, address _referrer, uint256 _quantity)
        external
        payable;
}
