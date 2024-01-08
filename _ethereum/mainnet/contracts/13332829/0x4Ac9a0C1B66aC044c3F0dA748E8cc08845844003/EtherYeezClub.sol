// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract EtherYeezClub is ERC721, Ownable, ERC721URIStorage, ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public maxSupply = 8888;
    
    bool public preSaleIsActive = true;
    uint256 public preSaleMaxSupply = 8888;
    
    bool public saleIsActive = false;
    
    uint256 public LOW_TIER_PRICE  = 40000000000000000;
    uint256 public MID_TIER_PRICE  = 35000000000000000;
    uint256 public HIGH_TIER_PRICE = 30000000000000000;

    uint public MIN_MINTABLE = 1;
    uint public MAX_MINTABLE = 9;

    uint public BONUS_MINTABLE = 1;

    string public finalDataMapURL;
    
    string private metaBaseURL;

    event PermanentURI(string _value, uint256 indexed _id);
    
    constructor(string memory _metaBaseURL) ERC721("EtherYeezClub", "EYC") {
        metaBaseURL = _metaBaseURL;
        _performMint(36);
    }
    
    function mintTokens(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale in inactive");
        require(numberOfTokens >= MIN_MINTABLE, "Minumum mintable amount is invalid");
        require(numberOfTokens <= MAX_MINTABLE, "Maximum mintable amount is invalid");
        require(SafeMath.add(totalSupply(), numberOfTokens) <= maxSupply, "Not enough tokens left");
        require(msg.value >= SafeMath.mul(calculateTokenPrice(numberOfTokens), numberOfTokens), "Amount of Ether sent is not correct.");
        
        _performMint(numberOfTokens);
    }

    function preMintTokens(uint numberOfTokens) public payable {
        require(preSaleIsActive, "Pre sale in inactive");
        require(numberOfTokens >= MIN_MINTABLE, "Minumum mintable amount is invalid");
        require(numberOfTokens <= MAX_MINTABLE, "Maximum mintable amount is invalid");
        require(msg.value >= SafeMath.mul(calculateTokenPrice(numberOfTokens), numberOfTokens), "Amount of Ether sent is not correct.");

        if (numberOfTokens == MAX_MINTABLE) {
            numberOfTokens = numberOfTokens + BONUS_MINTABLE;
        }

        require(SafeMath.add(totalSupply(), numberOfTokens) <= preSaleMaxSupply, "Not enough tokens left");
        _performMint(numberOfTokens);
    }

    function _performMint(uint numberOfTokens) private {
        for (uint i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            uint256 id = totalSupply();
            _safeMint(msg.sender, id);
        }
    }

    function mintTokensToWallet(uint numberOfTokens, address walletAddress) public onlyOwner {
        require(SafeMath.add(totalSupply(), numberOfTokens) <= maxSupply, "Not enough tokens left");

        for (uint i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            uint256 id = totalSupply();
            _safeMint(walletAddress, id);
        }
    }

    function calculateTokenPrice(uint numberOfTokens) public view returns (uint256) {
        uint256 tokenPrice = LOW_TIER_PRICE;

        if (numberOfTokens > MIN_MINTABLE && numberOfTokens < MAX_MINTABLE) {
            tokenPrice = MID_TIER_PRICE;
        } else if (numberOfTokens >= MAX_MINTABLE) {
            tokenPrice = HIGH_TIER_PRICE;
        }

        return tokenPrice; 
    }

    function setDataMap(string memory url) public onlyOwner { finalDataMapURL = url; }
    function setPermanentURI(string memory uri, uint256 tokenId) public onlyOwner { emit PermanentURI(uri, tokenId); }
    function updateLowTierPrice(uint256 newPrice) public onlyOwner { LOW_TIER_PRICE = newPrice; }
    function updateMidTierPrice(uint256 newPrice) public onlyOwner { MID_TIER_PRICE = newPrice; }
    function updateHighTierPrice(uint256 newPrice) public onlyOwner { HIGH_TIER_PRICE = newPrice; }
    function updateMinMintable(uint value) public onlyOwner { MIN_MINTABLE = value; }
    function updateMaxMintable(uint value) public onlyOwner { MAX_MINTABLE = value; }
    function updateBonusMintable(uint value) public onlyOwner { BONUS_MINTABLE = value; }
    function updatePreSaleMaxSupply(uint256 newMax) public onlyOwner { preSaleMaxSupply = newMax; }
    function activateSale() public onlyOwner { saleIsActive = true; }
    function deactivateSale() public onlyOwner { saleIsActive = false; }
    function activatePreSale() public onlyOwner { preSaleIsActive = true; }
    function deactivatePreSale() public onlyOwner { preSaleIsActive = false; }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function pause() public onlyOwner { _pause(); }
    function unpause() public onlyOwner { _unpause(); }
    
    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function setBaseURI(string memory baseURL) public onlyOwner { metaBaseURL = baseURL; }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return metaBaseURL;
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}