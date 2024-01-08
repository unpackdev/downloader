// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract PsychoPigs is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    // Constants
    uint256 public MAX_PIGS = 10000;
    uint256 public MAX_PIG_PURCHASE = 20;

    uint256 public pigPrice = 60000000000000000; //0.06 ETH
    bool public saleActive = false;

    // Private members
    string private _currentBaseURI;

    constructor() ERC721("PsychoPigs", "PSY") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /* 
        Toggle sale state 
    */
    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    /* 
        Set base price of the pigs
    */
    function setPigPrice(uint256 price) public onlyOwner {
        pigPrice = price;
    }

    /* 
        Sets the base URI, will be updated on reveal
    */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    /*
        Withdraw Psycho Pigs wallet funds
    */
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /*
        Internal mint function for minting pigs
    */
    function mint(uint amount) public onlyOwner {
        // Mint pigs
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId <= MAX_PIGS) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    /*
        Mints a given amount of pigs to the contract wallet 
    */
    function mintTo(uint amount, address _addr) public onlyOwner {
        // Mint pigs
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId <= MAX_PIGS) {
                _safeMint(_addr, tokenId);
            }
        }
    }

    /*
        Payable mint function for primary sale
    */
    function mintPig(uint amount) external payable{
        require(saleActive, "Sale is not active now");
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= MAX_PIG_PURCHASE, "Cannot mint more than 20 pigs at a time");
        require(totalSupply().add(amount) <= MAX_PIGS, "Cannot mint more than the maximum number of pigs");
        require(pigPrice.mul(amount) <= msg.value, "Ether value sent is not correct");

        // Mint pigs
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            if (tokenId < MAX_PIGS) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    /*
        Burn function, should not be used
    */
    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }
}
