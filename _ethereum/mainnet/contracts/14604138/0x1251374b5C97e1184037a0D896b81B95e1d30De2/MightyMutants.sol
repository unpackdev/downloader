// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MightyMutants is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public  MAX_SUPPLY = 3333;
    uint256 public  PUBLIC_PRICE = 0.015 ether;
    uint256 public MAX_PER_WALLET = 13;
    bool public SALE_IS_ACTIVE = true;
    
    mapping(address=>uint256) public tokenMinted;

    string private _baseURIextended;
    
    constructor() ERC721A("Mighty Mutants", "MM") {}

    function mint(uint256 nMints) external payable {
        require(SALE_IS_ACTIVE, "Minting is not active now");
        require(totalSupply() + nMints <= MAX_SUPPLY, "Exceeds max supply");
        uint256 oldMintedAmount =  tokenMinted[msg.sender];
        require(oldMintedAmount+nMints<=MAX_PER_WALLET,"Exceeds Mint Limits");
        if(totalSupply()>1000)
        {
          require(PUBLIC_PRICE * nMints <= msg.value, "Sent incorrect ETH value");  
        } else
        {

        uint256 remainingFreeMint =0;    
        if(oldMintedAmount<3)
        {
          remainingFreeMint = 3-oldMintedAmount; 
        }    
        require(PUBLIC_PRICE*(nMints-remainingFreeMint)<=msg.value,"Sent incorrect ETH value");

        uint256 newTotalSupply = totalSupply() + nMints;
        if(newTotalSupply>1000)
        require(PUBLIC_PRICE*(newTotalSupply-1000)<=msg.value,"Sent incorrect ETH value");
        }
        tokenMinted[msg.sender] = oldMintedAmount+nMints;
          _safeMint(msg.sender, nMints);   
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, (tokenId + 1).toString())) : '';
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(msg.sender, contractBalance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function flipSaleState() public onlyOwner {
        SALE_IS_ACTIVE = !SALE_IS_ACTIVE;
    }

    function changePublicPrice(uint256 newPublicPrice) public onlyOwner {
        PUBLIC_PRICE = newPublicPrice;
    }

    function changeMaxSupply(uint256 newMaxSupply) public onlyOwner {
        MAX_SUPPLY = newMaxSupply;
    }

    function changeMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        MAX_PER_WALLET = newMaxPerWallet;
    }

    receive() external payable {}

}
