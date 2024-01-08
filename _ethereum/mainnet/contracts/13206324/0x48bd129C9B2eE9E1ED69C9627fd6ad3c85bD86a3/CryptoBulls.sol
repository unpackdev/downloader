// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";


contract EtherBulls is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_BULLS = 6666;
    uint256 public constant MAX_PURCHASE = 50;

    uint256 public constant PRICE_PER_BULL = 60000000000000000 wei;

    bool private _saleIsActive = false;

    string private _metaBaseUri = "https://etherbulls.org/static/";

    string private _provenance = "";

    constructor() ERC721("EtherBulls", "EBULL") { }

    function mint(uint16 numberOfTokens) public payable {
        require(saleIsActive(), "Sale is not active");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 50 tokens per transaction");
        require(totalSupply().add(numberOfTokens) <= MAX_BULLS, "Insufficient supply");
        require(PRICE_PER_BULL.mul(numberOfTokens) == msg.value, "Ether value sent is incorrect");

        _mintTokens(numberOfTokens);
    }


    /* Owner functions */

    /**
     * Reserve a few bulls e.g. for giveaways
     */
    function reserve(uint16 numberOfTokens) external onlyOwner {
        require(totalSupply().add(numberOfTokens) <= MAX_BULLS, "Insufficient supply");
        _mintTokens(numberOfTokens);
    }

    function setSaleIsActive(bool active) external onlyOwner {
        _saleIsActive = active;
    }

    function setProvenance(string memory provHash) external onlyOwner {
        _provenance = provHash;
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

    function provenanceHash() public view returns (string memory) {
        return _provenance;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "nfts/", uint256(tokenId).toString(), "/metadata.json"));
    }

    /* Internal functions */
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
}
