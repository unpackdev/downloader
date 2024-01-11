// SPDX-License-Identifier: MIT
/*  
    Hyper Five Senses COLLECTION / 2022 
*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract HyperFiveSenses is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    string public unrevealURI;

    uint256 public price = 0.08 ether;
    uint256 public saleStartDate;

    mapping(address=>uint8) public allowlist;
    
    address private s1 = 0x07E6550526b9117AD9070FA2a8249dF34E838613 ;
    address private s2 = 0x0C2f634fE28e181757002e45c1111bccb04c1917 ;

    bool public _isReveal = false;
    bool public _isSaleActive = false;

    modifier onlyShareHolders() {
        require(msg.sender == s1 || msg.sender == s2 );
        _;
    }

    constructor( uint256 maxAmountPerMint, uint256 maxCollection) 
        ERC721A("HyperFiveSenses", "HFS", maxAmountPerMint, maxCollection) 
            {
            }

    function setAllowlist(address[] calldata addresses, uint8[] calldata mintAmount) external onlyOwner
    {
        require(addresses.length == mintAmount.length, "addresses does not match numSlots length");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = mintAmount[i];
        }
    }

    function withdraw() external onlyShareHolders {
        require(payable(s1).send(address(this).balance), "Send Failed");
    }
    
    function freeClaim(uint8 amount) external nonReentrant callerIsUser{
        require(_isSaleActive, "Sales is not active");
        require(saleStartDate <= block.timestamp);
        require(allowlist[msg.sender] >= amount, "not eligible for allowlist mint");
        require(totalSupply() + amount <= 1000, "reached max supply");
        allowlist[msg.sender] -= amount;
        mintFiveSenses(amount, msg.sender);
    }
    
    function publicMint(uint8 amount) external payable nonReentrant callerIsUser{
        require(_isSaleActive, "Sales is not active");
        require(saleStartDate <= block.timestamp);
        require(totalSupply() + amount <= 1000, "reached max supply");
        require( amount > 0, "At least one should be minted");
        require( price * amount <= msg.value, "Not enough ether sent");
        mintFiveSenses(amount, msg.sender);
    }    

    function saveMint(uint8 amount) external payable nonReentrant callerIsUser{
        require(_isSaleActive, "Sales is not active");
        require(saleStartDate <= block.timestamp);
        require(totalSupply() + amount <= collectionSize, "reached max supply");
        require( amount > 0, "At least one should be minted");
        require( price * amount <= msg.value, "Not enough ether sent");
        mintFiveSenses(amount, msg.sender);
    }    
    
    function devMint(uint8 amount, address to) external nonReentrant onlyOwner{
        require(totalSupply() + amount <= collectionSize, "reached max supply");
        mintFiveSenses(amount, to);
    }
        
    function airdrop(uint256 amount, address to) public onlyOwner {
        require(totalSupply() + amount <= collectionSize, "reached max supply");
        mintFiveSenses(amount, to);
    }
  
    function airdropToMany(address[] memory recipients) external onlyOwner {
        require(totalSupply().add(recipients.length) <= collectionSize, "reached max supply");
        for (uint256 i = 0; i < recipients.length; i++) {
         airdrop(1, recipients[i]);
        }
    }

    function mintFiveSenses(uint256 _amount, address to) private {
        _safeMint(to, _amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        if(!_isReveal) {
            return unrevealURI;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool newReveal) external onlyOwner {
        _isReveal = newReveal;
    }

    function setIsSalesActive(bool newSales) external onlyOwner {
        _isSaleActive = newSales;
    }

    function setSaleStartDate(uint256 newDate) public onlyOwner {
        saleStartDate = newDate;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}
