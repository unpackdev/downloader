// contracts/DyamineStandardNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./ProxyRegistry.sol";
import "./ERC721.sol";

//
//  DDDDDDD      EEEEEEEEEEEE
//  DD   DDD
//  DD     DD
//  DD       D   EEEEEEEEEEEE
//  DD     DD    EE
//  DD    DDD    EE
//  DDDDDDD      EEEEEEEEEEEE
//
// DYAMINE
// [https://dyamine.com]
// Standard mint-less ERC-721 Smart Contract
//

contract DyamineStandardNft is ERC721, Ownable {
    using Strings for uint256;

    string private _baseUri;
    uint256 public _totalSupply;

    // Addresses
    address private _creatorAddress;
    address private _withdrawAddress;
    address private _openSeaProxyAddress;
    address private _raribleProxyAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 totalSupply,
        string memory baseUri,
        address openSeaProxyAddress,
        address raribleProxyAddress
    ) ERC721(_name, _symbol) {
        _totalSupply = totalSupply;
        _baseUri = baseUri;
        _openSeaProxyAddress = openSeaProxyAddress;
        _raribleProxyAddress = raribleProxyAddress;
        _withdrawAddress = owner();
        _creatorAddress = owner();

        fireTransferEvents(address(0), owner());
    }

    function fireTransferEvents(address _from, address _to) internal {
        for (uint256 i = 0; i < _totalSupply; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            tokenId >= 0 && tokenId < _totalSupply,
            "URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for for gas-less listing.
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        // Whitelist Rarible proxy address too, for gas-less listing.
        if (operator == _raribleProxyAddress) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        require(
            tokenId >= 0 && tokenId < _totalSupply,
            "Dyamine ERC721: Owner query for nonexistent token"
        );

        if (!_exists(tokenId)) {
            return _creatorAddress;
        } else {
            return super.ownerOf(tokenId);
        }
    }

    function approve(address to, uint256 tokenId) public override {
        if (!_exists(tokenId)) {
            require(
                _checkCallerApproved(),
                "Dyamine ERC721: Not approved to approve"
            );
            require(
                _canMint(tokenId),
                "Dyamine ERC721: Invalid token occurance 2"
            );
            _approve(to, tokenId);
        } else {
            super.approve(to, tokenId);
        }
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address operator)
    {
        if (!_exists(tokenId)) {
            return super.owner();
        } else {
            return super.getApproved(tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            tokenId >= 0 && tokenId < _totalSupply,
            "Dyamine ERC721: Transfer attempt for nonexistent token, Dave."
        );

        if (!_exists(tokenId)) {
            _lazyMint(to, tokenId);
        } else {
            super.safeTransferFrom(from, to, tokenId, _data);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            tokenId >= 0 && tokenId < _totalSupply,
            "Dyamine ERC721: Transfer attempt for nonexistent token."
        );

        if (!_exists(tokenId)) {
            _lazyMint(to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function _lazyMint(address to, uint256 tokenId) internal {
        require(
            _checkCallerApproved(),
            "Dyamine ERC721: LazyMint - Not approved to mint"
        );
        require(
            _canMint(tokenId),
            "Dyamine ERC721: LazyMint - Invalid token ID"
        );
        _safeMint(to, tokenId);
        emit Transfer(_creatorAddress, to, tokenId);
    }

    function _canMint(uint256 _optionId) internal view returns (bool) {
        return
            !_exists(_optionId) && _optionId >= 0 && _optionId < _totalSupply;
    }

    function _checkCallerApproved() internal view returns (bool) {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyAddress);
        return
            address(proxyRegistry.proxies(owner())) == msg.sender ||
            _raribleProxyAddress == msg.sender ||
            owner() == msg.sender;
    }

    function setBaseUri(string memory _baseTokenURI) public onlyOwner {
        _baseUri = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function donate() public payable returns (string memory) {
        return "Thanks! Contact us and we'll reward your donation.";
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        _withdrawAddress = newAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_withdrawAddress).transfer(balance);
    }
}
