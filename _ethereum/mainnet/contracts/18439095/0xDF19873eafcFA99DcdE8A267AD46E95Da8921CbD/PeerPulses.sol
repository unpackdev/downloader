// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";

contract PeerPulses is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable(msg.sender)
{
    uint256 public maxSupply = 1000;
    uint256 public publicSalesTimestamp = 1698343200;
    uint256 public normalMintPrice = 0.025 ether;
    uint256 public totalNormalMint;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("PeerPulses", "PPS") EIP712("PeerPulses", "1.0.0") {}

    function mint(uint256 amount) external payable {
        require(isPublicSalesActive(), "Public sales is not active");
        require(amount <= 10, "Only 10 min");
        require(totalSupply() < maxSupply, "Sold out");
        require(
            totalSupply() + amount <= maxSupply,
            "Amount exceeds max supply"
        );
        require(amount > 0, "Invalid amount");
        require(msg.value >= amount * normalMintPrice, "Insufficient funds!");

        totalNormalMint += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "addresses and amounts doesn't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setNormalMintPrice(uint256 normalMintPrice_) external onlyOwner {
        normalMintPrice = normalMintPrice_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}