//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

contract NFT_AME is ERC721A, Ownable, PaymentSplitter {

    uint public MAX_SUPPLY = 10000;
    uint public PRICE = 0.1 ether;
    uint public MAX_PER_MINT = 10;
    bool public MINTING_ALLOWED = false;
    string public baseTokenURI;

    constructor(string memory baseURI, address[] memory payees, uint256[] memory shares) 
        ERC721A("NFT A.M.E Meca Collectible", "NFT_AME", MAX_PER_MINT)
        PaymentSplitter(payees, shares) 
        payable {
            setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) { return baseTokenURI; }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner { baseTokenURI = _baseTokenURI; }
    function setPrice(uint _price) external onlyOwner { PRICE = _price; }    
    function setMintingOpened(bool _open) external onlyOwner { MINTING_ALLOWED = _open; }
    function setMaxSupply(uint _maxSupply) external onlyOwner { MAX_SUPPLY = _maxSupply; }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function mint(uint256 quantity) external payable {
        require(MINTING_ALLOWED, "Minting is not opened for now!");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left!");
        require(quantity >0 && quantity <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE * quantity, "Not enough ether to purchase NFTs.");

        _safeMint(msg.sender, quantity);
    }

    function reserveNFTs(address[] memory who, uint256[] memory quantities) external onlyOwner {
        uint total = 0;
        for(uint i=0; i<who.length; i++) total += quantities[i];
        require(total < MAX_SUPPLY, "Not enough NFTs to reserve");

        for (uint i = 0; i < who.length; i++) {
            _safeMint(who[i], quantities[i]);
        }
    }
}