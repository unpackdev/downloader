// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract FlipBirbs is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant TOTAL_MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TRX = 10;

    mapping(address => uint256) public numberFreePerWallet;

    string private _baseTokenURI = "https://flipbirbs.xyz/media/";

    constructor() ERC721A("FlipBirbs", "FLIPBIRBS") {}

    modifier underMaxSupply(uint256 _quantity) {
        require(_totalMinted() + _quantity <= TOTAL_MAX_SUPPLY, "Purchase would exceed MAX SUPPLY");
        _;
    }

    modifier underMaxPerTransactions(uint256 _quantity) {
        require(_quantity <= MAX_PER_TRX, "Purchase would exceed MAX PER TRX");
        _;
    }

    function mint(uint256 _quantity)
        external
        underMaxSupply(_quantity)
        underMaxPerTransactions(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function ownerMint(uint256 _numberToMint) external onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(msg.sender, _numberToMint, "", false);
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        _mint(_recipient, _numberToMint, "", false);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}