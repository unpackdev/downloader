// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";



contract Rugbirds is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public isSaleActive = false;
    string private _baseURIextended;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PUBLIC_MINT = 10; 
    uint256 public constant FREE_TOKEN_PRICE = 0.0 ether;
    uint256 public constant PUBLIC_PRICE_PER_TOKEN = 0.025 ether;
    uint256 public constant FREE_MINT_AMOUNT = 1;
    uint256 public constant MAX_FREE_SUPPLY = 1000;

    //to track number of mints for 5 public
    mapping(address => uint8) private _mintedFromAddress;

    //to track nubmer for free mints
    mapping(address => uint8) private _mintedForFree;

    constructor() ERC721("Rugbirds", "RUG") {
    }

    // Activation Setters

    function activateSale(bool newState) public onlyOwner {
        isSaleActive = newState;
    }

    
    //Check available address FreeList Mints
    
    function alreadyMintedPublic(address addr) external view returns (uint8) { 
        return _mintedFromAddress[addr];
    }
    //Check available address Public Mints
    function alreadyMintedFree(address addr) external view returns (uint8) { 
        return _mintedForFree[addr];
    }

    // one mint for all
    function mint(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        if(_mintedForFree[msg.sender] == 0 && ts < MAX_FREE_SUPPLY){
            uint8 freeAmount = 1;
            require(isSaleActive, "Free mint is not active");
            require(freeAmount + _mintedForFree[msg.sender] <= FREE_MINT_AMOUNT, "Exceeded max available to purchase");
            require(ts + freeAmount <= MAX_FREE_SUPPLY, "Purchase would exceed max tokens for free mint");
            require(FREE_TOKEN_PRICE * freeAmount <= msg.value, "This is free");

            _mintedForFree[msg.sender] += freeAmount;
            for (uint256 i = 0; i < freeAmount; i++) {
                _safeMint(msg.sender, ts + i);
            }
        }else{
            require(isSaleActive, "Public Sale must be active to mint tokens");
            require(numberOfTokens <= 5,"Only 5 per Transaction allowed");
            require(_mintedFromAddress[msg.sender] + numberOfTokens <= MAX_PUBLIC_MINT, "can not mint this many");
            require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
            require(PUBLIC_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

            _mintedFromAddress[msg.sender] += numberOfTokens;

            for (uint256 i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, ts + i);
            }
        }
    }
     

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }
    

    function withdraw() public onlyOwner {
    
    (bool si, ) = payable(0xBB79c83Ec220A5d55302599D636DCC9b45bB7EAE).call{value: address(this).balance * 12 / 100}("");
    require(si);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);

    }
}