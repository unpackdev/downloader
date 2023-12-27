// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./BasicMintConfiguration.sol";
import "./Mint721Configuration.sol";
import "./IPFSEditionRendererConfiguration.sol";
import "./IMetadataRenderer.sol";

interface IMintFactoryEvents {
    /// @notice Emitted when a new contract is created.
    /// @param _contract The address of the newly created contract.
    /// @param _creator The address who created the contract.
    event ContractCreated(address indexed _contract, address indexed _creator);
}

interface IMintFactory is IMintFactoryEvents {
    error InvalidSalt();

    /// @notice Creates a new basic edition mint with the specified configurations.
    /// @dev Uses the CREATE2 opcode with `salt` to create a contract.
    /// `salt` should start with `msg.sender` and can be followed by any unique byte sequence.
    /// After the creation, the `ContractCreated` event is emitted.
    /// @param mint721Configuration The initial configuration for the NFT collection.
    /// @param metadataRenderer The metadata renderer contract address.
    /// @param metadataRendererData The configuration data for the metadata renderer, or 0 bytes if none.
    /// @param salt The CREATE2 salt used for predictable contract addressing. Must start with `msg.sender`.
    /// @param mintModuleAddresses The initial approved mint modules.
    /// @param mintModuleData The configuration data for the mint modules.
    /// @return contractAddress The address of the newly created contract.
    function createBasicEdition(
        Mint721Configuration calldata mint721Configuration,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererData,
        bytes32 salt,
        address[] calldata mintModuleAddresses,
        bytes[] calldata mintModuleData
    ) external returns (address contractAddress);

    /// @notice Creates a new basic edition mint with the specified configurations.
    /// @dev This is a functionally identical to `createBasicEdition`, but the four byte selector is 00000000.
    /// Uses the CREATE2 opcode with `salt` to create a contract.
    /// `salt` should start with `msg.sender` and can be followed by any unique byte sequence.
    /// After the creation, the `ContractCreated` event is emitted.
    /// @param mint721Configuration The initial configuration for the NFT collection.
    /// @param metadataRenderer The metadata renderer contract address.
    /// @param metadataRendererData The configuration data for the metadata renderer, or 0 bytes if none.
    /// @param salt The CREATE2 salt used for predictable contract addressing. Must start with `msg.sender`.
    /// @param mintModuleAddresses The initial approved mint modules.
    /// @param mintModuleData The configuration data for the mint modules.
    /// @return contractAddress The address of the newly created contract.
    function createBasicEdition_efficient_d3ea1b36(
        Mint721Configuration calldata mint721Configuration,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererData,
        bytes32 salt,
        address[] calldata mintModuleAddresses,
        bytes[] calldata mintModuleData
    ) external returns (address contractAddress);

    /// @notice Updates the contract implementations.
    /// @dev Can only be called by the protocol admin.
    /// @param mintModuleRegistry The new MintModuleRegistry contract address.
    /// @param mint721Implementation The new Mint721 contract address.
    function updateImplementations(address mintModuleRegistry, address mint721Implementation) external;
}
