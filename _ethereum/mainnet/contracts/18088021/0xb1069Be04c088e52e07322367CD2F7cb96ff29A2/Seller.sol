// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IPerseaSimpleCollectionSeq.sol";

contract Seller is Ownable, ReentrancyGuard, Pausable {

    IPerseaSimpleCollectionSeq public collection;

    constructor(address collectionAddress) Pausable() {
        collection = IPerseaSimpleCollectionSeq(collectionAddress);
    }

    function setCollection(address _currentContract) public whenNotPaused onlyOwner {
        collection = IPerseaSimpleCollectionSeq(_currentContract);
    }

    function payableMint(address _to, string memory _uriHash) public nonReentrant whenNotPaused payable {
        uint256 price = collection.getPrice();
        _validateSentValue(price);
        _mintAndTransfer(_to, price, _uriHash);
    }

    function _validateSentValue(uint256 _requiredValue) internal {
        require (msg.value >= _requiredValue, "Seller: Insufficient funds");
        if (msg.value > _requiredValue) {
            payable(msg.sender).transfer(msg.value - _requiredValue);
        }
    }

    function _mintAndTransfer(address _to, uint256 _valueToSend, string memory _uriHash) internal {
        collection.payableMint{value: _valueToSend}(_uriHash);
        uint256 newTokenId = collection.totalSupply();
        collection.transferFrom(address(this), _to, newTokenId);
    }

    function payableMintWithQuantity(uint256 _quantity, address _to, string[] memory _uriHashes) public nonReentrant whenNotPaused payable {
        require(_quantity == _uriHashes.length, "Seller: Arrays length mismatch");
        uint256 price = collection.getPrice();
        uint256 totalPrice = price * _quantity;
        _validateSentValue(totalPrice);
        for (uint256 i = 0; i < _quantity; i++) {
            _mintAndTransfer(_to, price, _uriHashes[i]);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function kill() external onlyOwner() {
        _pause();
        renounceOwnership();
    }
}