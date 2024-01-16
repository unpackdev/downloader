// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./Madworld1155.sol";
import "./Madworld721.sol";

contract MadworldFactory is Ownable {
    using SafeMath for uint256;

    uint256 public totalCollections;
    Madworld721 private impl;
    Madworld1155 private implMultiple;
    address private _proxyRegistryAddress;
    address private _exchangeAddress;

    mapping(address => address[]) public collections;
    mapping(address => address[]) public collectionsMutilpleSupply;

    event CollectionDeployed(
        address collection,
        address creator,
        string tokenURI
    );
    event CollectionRegistrySettled(address oldRegistry, address newRegistry);
    event CollectionExchangeSettled(address oldExchange, address newExchange);

    constructor(
        Madworld1155 _implMultiple,
        Madworld721 _impl,
        address _registry,
        address _exchange
    ) {
        require(_registry != address(0), "Invalid Address");
        require(_exchange != address(0), "Invalid Address");
        impl = _impl;
        implMultiple = _implMultiple;
        _proxyRegistryAddress = _registry;
        _exchangeAddress = _exchange;
    }

    function setProxyRegistry(address _registry) external onlyOwner {
        require(
            _registry != _proxyRegistryAddress,
            "MadworldFactory::SAME REGISTRY ADDRESS"
        );
        emit CollectionRegistrySettled(_proxyRegistryAddress, _registry);
        _proxyRegistryAddress = _registry;
    }

    function setNewExchange(address _exchange) external onlyOwner {
        require(
            _exchange != _exchangeAddress,
            "MadworldFactory::SAME EXCHANGE ADDRESS"
        );
        emit CollectionExchangeSettled(_exchangeAddress, _exchange);
        _exchangeAddress = _exchange;
    }

    function newCollection(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        string memory _contractURI
    ) external returns (address) {
        address newCollection = Clones.clone(address(impl));
        address sender = msg.sender;

        Madworld721(newCollection).initialize(
            _name,
            _symbol,
            _tokenURI,
            _contractURI,
            _proxyRegistryAddress,
            _exchangeAddress
        );

        collections[sender].push(newCollection);
        totalCollections = totalCollections.add(1);

        emit CollectionDeployed(newCollection, sender, _tokenURI);

        return newCollection;
    }

    function newCollectionMultipleSupply(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        string memory _contractURI
    ) external returns (address) {
        address newCollection = Clones.clone(address(implMultiple));
        address sender = msg.sender;

        Madworld1155(newCollection).initialize(
            _name,
            _symbol,
            _tokenURI,
            _contractURI,
            _proxyRegistryAddress,
            _exchangeAddress
        );

        collectionsMutilpleSupply[sender].push(newCollection);
        totalCollections = totalCollections.add(1);

        emit CollectionDeployed(newCollection, sender, _tokenURI);

        return newCollection;
    }
}
