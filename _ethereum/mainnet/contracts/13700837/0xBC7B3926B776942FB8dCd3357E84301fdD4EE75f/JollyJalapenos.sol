// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./draft-EIP712.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract JollyJalapenos is
    ERC721,
    EIP712,
    PaymentSplitter,
    ERC721Enumerable,
    AccessControl,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public PROVENANCE;

    uint256 public constant MAX_PURCHASE_ALLOW = 20;

    uint256 public collectionSize;

    uint256 public salePrice = 20000000000000000;

    string private baseUri;

    bool public saleIsActive = false;

    constructor(address[] memory payees, uint256[] memory shares, uint256 _collectionSize)
        ERC721("Jolly Jalapenos", "JOLLYJ")
        EIP712("Jolly Jalapenos", "1.0.0")
        PaymentSplitter(payees, shares)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        collectionSize = _collectionSize;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setSalePrice(uint256 _salePrice) public onlyOwner {
        require(_salePrice > 0, "Sale price must be greather than 0");
        salePrice = _salePrice;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setCollectionSize(uint256 _collectionSize) public onlyOwner {
        require(
            collectionSize > totalSupply(),
            "The collection size can't be less than the total supply"
        );

        collectionSize = _collectionSize;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setSaleState(bool newState) public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleIsActive = newState;
    }

    function reserve(uint256 n) public onlyOwner {
        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender);
        }
    }

    function sale(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active to mint tokens");
        require(
            numberOfTokens <= MAX_PURCHASE_ALLOW,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= collectionSize,
            "Purchase would exceed max supply"
        );
        require(
            numberOfTokens * salePrice <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function _safeMint(address to) private {
        require(
            totalSupply() < collectionSize,
            "Minting will exceed the max supply"
        );

        uint256 currentTokenId = _tokenIdCounter.current();
        _safeMint(to, currentTokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
