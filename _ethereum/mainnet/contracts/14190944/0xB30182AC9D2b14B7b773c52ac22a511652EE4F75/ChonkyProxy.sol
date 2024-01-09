// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MetadataStorage.sol";
import "./IERC721.sol";
import "./Proxy.sol";
import "./SafeOwnable.sol";
import "./IERC165.sol";

import "./ERC165Storage.sol";

import "./ChonkyNFTStorage.sol";

contract ChonkyProxy is Proxy, SafeOwnable {
    using ChonkyNFTStorage for ChonkyNFTStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;

    event Upgraded(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    constructor(
        address implementation,
        address chonkyAttributes,
        address chonkyMetadata,
        address chonkySet
    ) {
        OwnableStorage.layout().setOwner(msg.sender);
        ChonkyNFTStorage.layout().implementation = implementation;

        {
            ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage
                .layout();
            l.name = "Chonkys";
            l.symbol = "CK";
        }

        {
            ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();
            l.chonkyAttributes = chonkyAttributes;
            l.chonkyMetadata = chonkyMetadata;
            l.chonkySet = chonkySet;
        }

        {
            ERC165Storage.Layout storage l = ERC165Storage.layout();
            l.setSupportedInterface(type(IERC165).interfaceId, true);
            l.setSupportedInterface(type(IERC721).interfaceId, true);
        }
    }

    receive() external payable {}

    function _getImplementation() internal view override returns (address) {
        return ChonkyNFTStorage.layout().implementation;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function setImplementation(address implementation) external onlyOwner {
        address oldImplementation = ChonkyNFTStorage.layout().implementation;
        ChonkyNFTStorage.layout().implementation = implementation;
        emit Upgraded(oldImplementation, implementation);
    }
}
