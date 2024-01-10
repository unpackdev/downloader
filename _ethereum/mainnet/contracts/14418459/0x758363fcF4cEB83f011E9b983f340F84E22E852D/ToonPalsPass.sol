//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";

error SaleNotActive();
error RecipientIsNotEOA();
error MaxSupplyExceeded();
error MaxMintQuantityExceeded();
error IncorrectEtherValueSent();
error ValueUnchanged();
error InvalidValue();

contract OSOwnableDelegateProxy {}

contract OSProxyRegistry {
    mapping(address => OSOwnableDelegateProxy) public proxies;
}

contract ToonPalsPass is Ownable, ERC721A {
    bool public saleActive = false;
    uint256 public maxSupply = 0;
    uint256 public maxMintQuantity = 1;
    uint256 public mintValue = 0.01 ether;
    string public baseURI = "";

    OSProxyRegistry private _osProxyRegistry;

    event SaleActiveUpdated(bool oldSaleActive, bool saleActive);
    event MaxSupplyUpdated(uint256 oldMaxSupply, uint256 maxSupply);
    event MaxMintQuantityUpdated(
        uint256 oldMaxMintQuantity,
        uint256 maxMintQuantity
    );
    event MintValueUpdated(uint256 oldMintValue, uint256 mintValue);
    event BaseURIUpdated(string oldBaseURI, string baseURI);

    constructor(string memory baseURI_, address osProxyRegistryAddress)
        ERC721A("ToonPals Pass", "TPP")
    {
        baseURI = baseURI_;
        _osProxyRegistry = OSProxyRegistry(osProxyRegistryAddress);
    }

    function mint(uint256 quantity) external payable {
        if (saleActive != true) revert SaleNotActive();
        if (_msgSender() != tx.origin) revert RecipientIsNotEOA();
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyExceeded();
        if (quantity > maxMintQuantity) revert MaxMintQuantityExceeded();
        if (quantity * mintValue != msg.value) revert IncorrectEtherValueSent();

        _safeMint(_msgSender(), quantity);
    }

    function setSaleActive(bool saleActive_) external onlyOwner {
        if (saleActive_ == saleActive) revert ValueUnchanged();

        bool oldSaleActive = saleActive;
        saleActive = saleActive_;

        emit SaleActiveUpdated(oldSaleActive, saleActive_);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        if (maxSupply_ == maxSupply) revert ValueUnchanged();
        if (maxSupply_ < maxSupply) revert InvalidValue();

        uint256 oldMaxSupply = maxSupply;
        maxSupply = maxSupply_;

        emit MaxSupplyUpdated(oldMaxSupply, maxSupply_);
    }

    function setMaxMintQuantity(uint256 maxMintQuantity_) external onlyOwner {
        if (maxMintQuantity_ == maxMintQuantity) revert ValueUnchanged();
        if (maxMintQuantity_ < maxMintQuantity) revert InvalidValue();

        uint256 oldMaxMintQuantity = maxMintQuantity;
        maxMintQuantity = maxMintQuantity_;

        emit MaxMintQuantityUpdated(oldMaxMintQuantity, maxMintQuantity_);
    }

    function setMintValue(uint256 mintValue_) external onlyOwner {
        if (mintValue_ == mintValue) revert ValueUnchanged();
        if (mintValue_ == 0) revert InvalidValue();

        uint256 oldMintValue = mintValue;
        mintValue = mintValue_;

        emit MintValueUpdated(oldMintValue, mintValue_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        if (
            keccak256(abi.encodePacked(baseURI_)) ==
            keccak256(abi.encodePacked(_baseURI()))
        ) revert ValueUnchanged();

        string memory oldBaseURI = _baseURI();
        baseURI = baseURI_;

        emit BaseURIUpdated(oldBaseURI, baseURI_);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator) ||
            (address(_osProxyRegistry) != address(0) &&
                address(_osProxyRegistry.proxies(owner_)) == operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
