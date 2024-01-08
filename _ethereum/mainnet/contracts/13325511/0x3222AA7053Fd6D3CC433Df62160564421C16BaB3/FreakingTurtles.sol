/**
 * @title Freaking Turtles contract
 * @dev Extends ERC721 Non-Fungible Token Standard Basic Implementation
 */

 /**
 *  SPDX-License-Identifier: MIT
 */

/*
                    __
         .,-;-;-,. /'_\
       _/_/_/_|_\_\) /
     '-<_><_><_><_>=/\
       `/_/====/_/-'\_\
        ""     ""    ""
 */
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract FreakingTurtles is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    event Minted(address indexed to, uint256 indexed tokenId);

    string public provenance;
    string private _baseTokenURI;

    uint256 public constant PRE_SALE_PRICE = 0.04 ether;
    uint256 public constant SALE_PRICE = 0.05 ether;
    uint256 public constant MAX_PRE_SALE_PURCHASE = 10;
    uint256 public constant MAX_SALE_PURCHASE = 20;

    uint256 public constant MAX_TOKENS = 9999;
    uint256 public constant MAX_PRE_SOLD = 1000;

    uint256 public preSoldCount;

    bool public preSaleIsActive;
    bool public saleIsActive;

    mapping (address => bool) public preSaleAddresses;
    mapping (address => uint256) public reservedClaims;

    constructor() ERC721("Freaking Turtles", "FTT") {
        preSaleIsActive = false;
        saleIsActive = false;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setProvenance(string memory prov) external onlyOwner {
        provenance = prov;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : "";
    }

    // WHITELIST
    function whitelistAddresses(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            preSaleAddresses[addrs[i]] = true;
        }
    }

    // RESERVE
    function reserveClaims(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint i=0; i < addresses.length; i++){
            reservedClaims[addresses[i]] = amounts[i];
        }
    }

    // START PAUSE
    function startPreSale() external onlyOwner {
        require(preSaleIsActive == false, "Pre Sale is started");
        require(saleIsActive == false, "Sale is started");
        preSaleIsActive = true;
    }

    function pausePreSale() external onlyOwner {
        require(preSaleIsActive == true, "Pre Sale is paused");
        preSaleIsActive = false;
    }

    function startSale() external onlyOwner {
        require(preSaleIsActive == false, "Pre Sale is started");
        require(saleIsActive == false, "Sale is started");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale is paused");
        saleIsActive = false;
    }

    // MINT
    function claimReserved() external {
        require(reservedClaims[msg.sender] > 0, "Nothing to claim");

        uint256 amount = reservedClaims[msg.sender];
        reservedClaims[msg.sender] = 0;
        
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintPreSale(uint256 numberOfTokens) external payable {
        require(preSaleIsActive == true, "Pre Sale must be active to mint tokens");
        require(preSaleAddresses[msg.sender] == true, "Address is not whitelisted");
        require(numberOfTokens > 0, "At least one token must be minted");
        require(numberOfTokens <= MAX_PRE_SALE_PURCHASE, "Exceeded max token purchase");
        require(preSoldCount.add(numberOfTokens) <= MAX_PRE_SOLD, "Purchase would exceed max supply of pre sale");
        require(PRE_SALE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            emit Minted(msg.sender, supply + i);
            preSoldCount++;
        }
    }

    function mintSale(uint256 numberOfTokens) external payable {
        require(saleIsActive == true, "Sale must be active to mint tokens");
        require(numberOfTokens > 0, "At least one token must be minted");
        require(numberOfTokens <= MAX_SALE_PURCHASE, "Exceeded max token purchase");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(SALE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            emit Minted(msg.sender, supply + i);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
