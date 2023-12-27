// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IMetadataRenderer.sol";
import "./LibClone.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IMintFactory.sol";
import "./Mint721Configuration.sol";
import "./IMint721.sol";

contract MintFactory is IMintFactory, Ownable, Pausable {
    /// @notice The mint module registry.
    address public mintModuleRegistry;
    /// @notice The implementation of Mint721 to be cloned here.
    address public mint721Implementation;

    error InvalidAddress();

    constructor() {
        _initializeOwner(tx.origin);
    }

    /// @inheritdoc IMintFactory
    function createBasicEdition(
        Mint721Configuration calldata mint721Configuration,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererData,
        bytes32 salt,
        address[] calldata mintModuleAddresses,
        bytes[] calldata mintModuleData
    ) external returns (address contractAddress) {
        return _createBasicEdtion(
            mint721Configuration, metadataRenderer, metadataRendererData, salt, mintModuleAddresses, mintModuleData
        );
    }

    /// @inheritdoc IMintFactory
    function createBasicEdition_efficient_d3ea1b36(
        Mint721Configuration calldata mint721Configuration,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererData,
        bytes32 salt,
        address[] calldata mintModuleAddresses,
        bytes[] calldata mintModuleData
    ) external returns (address contractAddress) {
        return _createBasicEdtion(
            mint721Configuration, metadataRenderer, metadataRendererData, salt, mintModuleAddresses, mintModuleData
        );
    }

    function _createBasicEdtion(
        Mint721Configuration calldata mint721Configuration,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererData,
        bytes32 salt,
        address[] calldata mintModuleAddresses,
        bytes[] calldata mintModuleData
    ) internal whenNotPaused returns (address contractAddress) {
        if (address(bytes20(salt)) != msg.sender) revert InvalidSalt();

        contractAddress = LibClone.cloneDeterministic(mint721Implementation, salt);

        IMint721(contractAddress).initialize(
            mint721Configuration,
            mintModuleRegistry,
            metadataRenderer,
            metadataRendererData,
            mintModuleAddresses,
            mintModuleData,
            msg.sender
        );

        emit ContractCreated(contractAddress, msg.sender);
    }

    /// @inheritdoc IMintFactory
    function updateImplementations(address _mintModuleRegistry, address _mint721Implementation) external onlyOwner {
        if (_mintModuleRegistry == address(0) || _mint721Implementation == address(0)) {
            revert InvalidAddress();
        }

        mintModuleRegistry = _mintModuleRegistry;
        mint721Implementation = _mint721Implementation;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
