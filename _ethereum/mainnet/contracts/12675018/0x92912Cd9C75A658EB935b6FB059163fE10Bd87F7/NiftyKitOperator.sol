//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./NiftyKitBase.sol";
import "./NiftyKitCollection.sol";

contract NiftyKitOperator is NiftyKitBase {
    event CollectionCreated(address indexed cAddress);
    event TokenMinted(
        address indexed cAddress,
        string manifest,
        uint256 indexed id
    );

    function createCollection(
        address creator,
        string calldata name,
        string calldata symbol
    ) external onlyAdmin {
        NiftyKitCollection collection = new NiftyKitCollection(name, symbol);
        collection.transferOwnership(creator);
        emit CollectionCreated(address(collection));
    }

    function batchMint(
        address[] calldata cAddresses,
        string[] calldata manifests,
        address[] calldata recipients
    ) external onlyAdmin {
        for (uint256 i = 0; i < cAddresses.length; i++) {
            NiftyKitCollection collection = NiftyKitCollection(cAddresses[i]);
            emit TokenMinted(
                cAddresses[i],
                manifests[i],
                collection.mint(recipients[i], manifests[i])
            );
        }
    }

    function transfer(
        address cAddress,
        address from,
        address to,
        uint256 tokenId
    ) external onlyAdmin {
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        collection.transfer(from, to, tokenId);
    }

    function burn(address cAddress, uint256 tokenId) external onlyAdmin {
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        collection.burn(tokenId);
    }

    function setCommission(address cAddress, uint256 commission)
        external
        onlyAdmin
    {
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        collection.setCommission(commission);
    }

    function addCollectionAdmin(address cAddress, address account)
        external
        onlyAdmin
    {
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        collection.grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeCollectionAdmin(address cAddress, address account)
        external
        onlyAdmin
    {
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        collection.revokeRole(DEFAULT_ADMIN_ROLE, account);
    }
}
