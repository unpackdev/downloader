// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SicFundV2 is ERC1155, Ownable, ERC1155Burnable {
    // prices per token in WEI 
    mapping(uint256 => uint256) public tokenPrices;
    
    // are sales enabled?
    bool public salesOn = true;

    mapping (uint256 => string) private _uris;

    // amount of ETH accomulated by contract
    uint256 public totalBalance = 0;

    constructor() ERC1155("SicFundV2") {
        _mint(0xA15b531D6e335b9fa3BfBe859E6650766B1DcB60, 1, 2000, "");
        setTokenUri(1, "https://ipfs.io/ipfs/bafkreifw2zxyso367gb5f4zs4sfkcpbjjturrlfyycdk7z2ldvhadisk2a");
        tokenPrices[1] = 150000000000000000; // (0.15 ETH)
    }
    
    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }
    
    function setTokenUri(uint256 tokenId, string memory _uri) public onlyOwner {
        _uris[tokenId] = _uri; 
    }

    function toggleSales(bool _flag) public onlyOwner {
        salesOn = _flag;
    }    

    function mint(address recipient, uint256 tokenId, uint256 amount, string memory _uri, uint256 price) public onlyOwner  {
        _mint(recipient, tokenId, amount, "");
        setTokenUri(tokenId, _uri);
        tokenPrices[tokenId] = price;
    }

    function purchase(address recipient, uint256 amount, uint256 tokenId) public payable {
        require(amount > 0, "amount must be greater than zero");
        require(amount * tokenPrices[tokenId] <= msg.value, "insufficient funds");
        require(balanceOf(owner(), tokenId) >= amount, "not enough for sale");
        require(isApprovedForAll(owner(), address(this)), "not approved for moving tokens");
        require(salesOn == true, "sales not active");

        SicFundV2(address(this)).safeTransferFrom(owner(), recipient, tokenId, amount, "");
        totalBalance += msg.value;
    }

    function withdraw(address _recipient, uint256 _amount) onlyOwner public {
        require(_amount <= address(this).balance, "not sufficient funds");
        payable(_recipient).transfer(_amount);
        totalBalance = totalBalance - _amount;
    }    
}