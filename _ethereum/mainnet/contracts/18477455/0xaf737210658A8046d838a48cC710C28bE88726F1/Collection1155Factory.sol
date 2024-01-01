// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./Ownable.sol";

import "./Collection1155.sol";
import "./ICollection1155Factory.sol";

// final
contract Collection1155Factory is
    OwnableUpgradeable,
    ICollection1155Factory
{
    using Clones for address;
    address private implementationContract;

    event Collection1155Created(
        address collection,
        address creator,
        string uri
    );

    function initialize(
        address implementationContract_
    ) public initializer {
        __Ownable_init();
        implementationContract = implementationContract_;
    }

    function createCollection(
        string memory uri,
        string memory collectionName,
        string memory collectionSymbol
    ) public override returns (address clone_) {
        
        require(bytes(uri).length > 0, "ERC2981RoyaltiesFactory: URI must not be empty");
        require(bytes(collectionName).length > 0, "ERC2981RoyaltiesFactory: collectionSymbol must not be empty");
        require(bytes(collectionSymbol).length > 0, "ERC2981RoyaltiesFactory: collectionSymbol must not be empty");

        clone_ = Clones.clone(implementationContract);
        _initializeClone(
            clone_,
            uri,
            collectionName,
            collectionSymbol
        );
    }

    function getImplementationContract()
        public
        view
        onlyOwner
        override
        returns (address){
        return implementationContract;
    }

    function setImplementationContract( 
        address implementationContract_ 
    ) external onlyOwner override {
        implementationContract = implementationContract_;
    }

    function _initializeClone(
        address clone_,
        string memory uri,
        string memory collectionName,
        string memory collectionSymbol
    ) internal {
        Collection1155(clone_).initialize(
            msg.sender,
            uri,
            collectionName,
            collectionSymbol
        );
        emit Collection1155Created(clone_, msg.sender, uri);
    }

}
