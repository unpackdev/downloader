// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721InteractProxy.sol";
import "./IERC721Receiver.sol";

contract MintProxy is ERC721InteractProxy, IERC721Receiver {
    uint256 public price;
    uint256 public _originalPrice;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        data; tokenId; from; operator;
        return this.onERC721Received.selector;
    }

    constructor() {
        price = 0.005e18;
        _originalPrice = 0.035e18;
        setContract(address(0xc7f599640Ae884F4ec4555265C82cd57cac76795));
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setOriginalPrice(uint256 _price) public onlyOwner {
        _originalPrice = _price;
    }

    function release() public onlyOwner {
        address to = msg.sender;
        (bool sent, bytes memory data) = to.call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed to call release()");
        data;
    }

    function retrieveToken(uint256 _tokenId) public onlyOwner {
        address to = msg.sender;
        tokenContract.safeTransferFrom(address(this), to, _tokenId);
    }

    modifier costs(uint256 _price) {
        require(msg.value >= _price);
        _;
    }
    modifier reserve(uint256 _price) {
        require(
            address(this).balance >= _price,
            "Not enough ETH in the reseve."
        );
        _;
    }

    function mint() public payable costs(price) reserve(_originalTokenCost()) {
        _mintTo(msg.sender);
    }

    function mintMany(uint256 _amount)
        public
        payable
        costs(price * _amount)
        reserve(_originalTokenCost() * _amount)
    {
        _mintToMany(msg.sender, _amount);
    }

    function _mintTo(address _to) internal {
        _mint();
        tokenContract.transferFrom(
            address(this),
            _to,
            tokenContract.totalSupply() - 1
        );
    }

    function _mintToMany(address _to, uint256 _amount) internal {
        _mintMany(_amount);
        for (uint256 i = 0; i < _amount; i++) {
            tokenContract.transferFrom(
                address(this),
                _to,
                tokenContract.totalSupply() - 1 - i
            );
        }
    }

    function deposit() public payable {}

    // !CHANGE THESE DEPENDANT ON CONTRACT IMPLEMENTATION
    function _mint() internal {
        tokenContract.mint{value: _originalTokenCost()}();
    }

    function _mintMany(uint256 _amount) internal {
        tokenContract.mintMany{value: (_amount * _originalTokenCost())}(
            _amount
        );
    }

    function _originalTokenCost() internal view returns (uint256) {
        return _originalPrice;
    }

    function totalSupply() public view returns (uint256) {
        return tokenContract.totalSupply();
    }
}
