// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract AstroClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_NFT = 10000;
    uint256 public constant MAX_NFT_PURCHASE = 10;
    uint256 public constant PRICE_PER_NFT = 70000000000000000 wei; // 0.08 Eth
    
    bool private _saleIsActive = false;
    uint256 public maxMintSupply = 0;

    string private _metaBaseUri = "https://astro-club.s3.amazonaws.com/metadata/";

    constructor() ERC721("AstroClub", "ASTRO") { }

    function mint(uint16 numberOfTokens) public payable {
        require(saleIsActive(), "Sale is not active");
        require(numberOfTokens <= MAX_NFT_PURCHASE, "Can only mint 10 tokens per transaction");
        require(totalSupply().add(numberOfTokens) <= maxMintSupply, "Insufficient supply try next wave");
        require(totalSupply().add(numberOfTokens) <= MAX_NFT, "Insufficient supply 10k");
        require(PRICE_PER_NFT.mul(numberOfTokens) == msg.value, "Ether value sent is incorrect");

        _mintTokens(msg.sender, numberOfTokens);
    }

    /* Owner functions */
    function ownerMint(address account, uint16 numberOfTokens) external onlyOwner {
        require(totalSupply().add(numberOfTokens) <= MAX_NFT, "Insufficient supply");
        _mintTokens(account, numberOfTokens);
    }

    function setSaleIsActive(bool active, uint256 newMaxMintSupply) external onlyOwner {
        _saleIsActive = active;
        maxMintSupply = newMaxMintSupply;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* View functions */
    function saleIsActive() public view returns (bool) {
        return _saleIsActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString(), "/metadata.json"));
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "metadata.json"));
    }

    /* Internal functions */
    function _mintTokens(address account, uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(account, tokenId);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
}