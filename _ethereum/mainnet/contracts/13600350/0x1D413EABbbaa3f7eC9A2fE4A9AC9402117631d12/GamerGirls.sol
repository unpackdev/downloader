// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";

contract GamerGirls is ERC721, ERC721Enumerable, Ownable {
    using Math for uint256;
    using Strings for string;
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_GGS = 10000;
    uint256 public maxGGPurchase = 12;
    uint256 public ggPrice = 0.07 ether;
    bool public saleIsActive = false;
    string public _baseGGURI;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public levels;

    event GamerGirlMinted(uint256 tokenId);

    constructor(string memory baseURI) ERC721("GamerGirls", "GGIRL") {
        _baseGGURI = baseURI;
    }

    function reserveGamerGirls(uint256 reserveAmount) public onlyOwner {
        for (uint256 i = 1; i <= reserveAmount; i++) {
            createCollectible(msg.sender);
        }
    }

    function giveAway(address to, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            createCollectible(to);
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseGGURI = newuri;
    }

    function setMaxGGPurchase(uint256 newMax) public onlyOwner {
        maxGGPurchase = newMax;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "ggPrice must be greater than zero");
        ggPrice = newCost;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "getLevel query for nonexistent token");
        return levels[tokenId];
    }

    function mintGamerGirl(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint GamerGirl");
        require(numberOfTokens <= maxGGPurchase, "# of new NFTs is limited per single transaction");
        require((ggPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require((totalSupply() + numberOfTokens) <= MAX_GGS, "Purchase would exceed max supply of GamerGirls");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_GGS) {
                createCollectible(msg.sender); 
            }
        }
    }

    function createCollectible(address mintAddress) private {
        uint256 mintIndex = _tokenIdCounter.current();
        if (mintIndex < MAX_GGS) {
            _safeMint(mintAddress, mintIndex);
            _tokenIdCounter.increment();
            levels[mintIndex] = 1;
            emit GamerGirlMinted(mintIndex);
        }    
    }

    function transferFrom(address from, address to,uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        levels[tokenId] += 1;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
        levels[tokenId] += 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = super.tokenURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", getLevel(tokenId).toString())): "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseGGURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
