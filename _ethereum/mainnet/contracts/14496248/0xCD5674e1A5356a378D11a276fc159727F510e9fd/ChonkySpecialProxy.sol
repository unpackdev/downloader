// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MetadataStorage.sol";
import "./IERC721.sol";
import "./Proxy.sol";
import "./SafeOwnable.sol";
import "./IERC165.sol";

import "./ERC165Storage.sol";
import "./ChonkySpecialStorage.sol";

contract ChonkySpecialProxy is Proxy, SafeOwnable {
    using ChonkySpecialStorage for OwnableStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;

    event Upgraded(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    constructor(address implementation) {
        OwnableStorage.layout().setOwner(msg.sender);
        ChonkySpecialStorage.layout().implementation = implementation;

        {
            ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage
                .layout();
            l.name = "Chonkys Special";
            l.symbol = "CKSP";
        }

        {
            ERC165Storage.Layout storage l = ERC165Storage.layout();
            l.setSupportedInterface(type(IERC165).interfaceId, true);
            l.setSupportedInterface(type(IERC721).interfaceId, true);
        }
    }

    function _getImplementation() internal view override returns (address) {
        return ChonkySpecialStorage.layout().implementation;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function setImplementation(address implementation) external onlyOwner {
        address oldImplementation = ChonkySpecialStorage
            .layout()
            .implementation;
        ChonkySpecialStorage.layout().implementation = implementation;
        emit Upgraded(oldImplementation, implementation);
    }
}
