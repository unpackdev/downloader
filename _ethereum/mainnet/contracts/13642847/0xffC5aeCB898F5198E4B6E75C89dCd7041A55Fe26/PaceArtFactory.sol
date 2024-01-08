// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./PaceArtStore.sol";

contract PaceArtFactory is Ownable {
    using SafeMath for uint;

    uint public totalCollections;
    PaceArtStore private impl;
    address private _proxyRegistryAddress;
    address private _exchangeAddress;

    mapping(address => address[]) public collections;

    event CollectionDeployed(address collection, address creator);
    event CollectionRegistrySettled(address oldRegistry, address newRegistry);
    event CollectionExchangeSettled(address oldExchange, address newExchange);

    constructor(PaceArtStore _impl, address _registry, address _exchange) {
        impl = _impl;
        _proxyRegistryAddress = _registry;
        _exchangeAddress = _exchange;
    }

    function setProxyRegistry(address _registry) external onlyOwner {
        require(_registry != _proxyRegistryAddress, "PaceArtFactory::SAME REGISTRY ADDRESS");
        emit CollectionRegistrySettled(_proxyRegistryAddress, _registry);
        _proxyRegistryAddress = _registry;
    }

    function setNewExchange(address _exchange) external onlyOwner {
        require(_exchange != _exchangeAddress, "PaceArtFactory::SAME EXCHANGE ADDRESS");
        emit CollectionExchangeSettled(_exchangeAddress, _exchange);
        _exchangeAddress = _exchange;
    }

    function newCollection(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI
    ) external returns(address) {
        address newCollection = Clones.clone(address(impl));
        address sender = msg.sender;
        
        PaceArtStore(newCollection).initialize(_name, _symbol, _tokenURI, _proxyRegistryAddress, _exchangeAddress);
        
        collections[sender].push(newCollection);
        totalCollections = totalCollections.add(1);

        emit CollectionDeployed(newCollection, sender);

        return newCollection;
    }
}
