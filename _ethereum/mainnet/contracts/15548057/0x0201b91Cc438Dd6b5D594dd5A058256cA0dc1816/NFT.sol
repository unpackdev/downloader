//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract NFT is ERC721Enumerable, Ownable {
    
    string _baseTokenURI;
    uint256 public _reserved = 500;
    uint256 public PRICE = 0.08 ether;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_MINT = 5;  //max number of token that can be minted by a single address
    uint256 public MAX_CURRENT_PHASE = 4000;  //max number of token that can be minted in the current phase
    bool public _paused = false;
    bool public isOwnerMintActive = false;
    mapping(address => uint) public tokensMinted;  //tokens minted by each address
    mapping(address => uint) public tokensMintedOwnerPeriod;  //tokens minted by each address in free minting phase


    constructor(string memory baseURI) ERC721("Spectralbirds", "SPECTRE") {
        setBaseURI(baseURI);

        _safeMint(msg.sender, 0);
    }

    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = totalSupply();

        require( !_paused, "Sale paused.");
        require(tokensMinted[msg.sender]+_count <= MAX_MINT, "Exceeded max available to purchase");
        require((totalMinted + _count) <= (MAX_SUPPLY-_reserved), "Not enough NFTs left!");
        require((totalMinted + _count) <= MAX_CURRENT_PHASE, "Not enough NFTs left in this phase!");  //check that total minted quantity does not exceed current allowed phase
        require(msg.value >= (PRICE * _count), "Not enough ETH to purchase NFTs.");

        tokensMinted[msg.sender] += _count;
        for (uint256 i = 0; i < _count; i++) {
            _safeMint( msg.sender, totalMinted + i );
        }
    }

    function ownersMint(uint256 numTokens) public payable {
        uint256 totalMinted = totalSupply();
        uint256 ownedQuantity = balanceOf(msg.sender)/2;

        require(isOwnerMintActive, "Owner only minting not active");
        require((totalMinted + numTokens) <= (MAX_SUPPLY-_reserved), "Not enough NFTs left!");
        require(tokensMintedOwnerPeriod[msg.sender]+numTokens <= ownedQuantity, "Exceeded max available to free mint");  //check if the quantity of free minted tokens are less then the actual quantity of owned NFT
        require((totalMinted + numTokens) <= MAX_CURRENT_PHASE, "Not enough NFTs left in this phase!");  //check that total minted quantity does not exceed current allowed phase


        tokensMintedOwnerPeriod[msg.sender] += numTokens;
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, totalMinted + i);
        }
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {

        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return PRICE;
    }

    function reserveNFTs(uint256 _amount) external onlyOwner {
        uint256 totalMinted = totalSupply();

        require( _amount <= _reserved, "Exceeds reserved supply" );
        require((totalMinted + _amount) <= MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint( msg.sender, totalMinted + i );
        }

        _reserved -= _amount;
    }

    function setPause(bool val) public onlyOwner {
        _paused = val;
    }

    function setOwnerMintActive(bool val) public onlyOwner {
        isOwnerMintActive = val;
    }

    function setMaxCurrentPhase(uint256 val) public onlyOwner {
        MAX_CURRENT_PHASE = val;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        require(payable(this.owner()).send(balance));
    }

}