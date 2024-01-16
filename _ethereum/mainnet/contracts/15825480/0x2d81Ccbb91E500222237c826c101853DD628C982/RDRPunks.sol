// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./ERC721FCOMMON.sol";
import "./AllowListWithAmount.sol";

/**
 * @title RDRPunks contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract RDRPunks is ERC721FCOMMON, AllowListWithAmount {
    
    uint256 public tokenPrice = 0.015 ether; 
    uint256 public constant MAX_TOKENS = 10000;
    
    uint public constant MAX_PURCHASE = 4; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 201; // set 1 to high to avoid some gas
    
    bool public saleIsActive;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    
    event PriceChange(address _by, uint256 price);
    
    constructor() ERC721FCOMMON("RDRPunks", "RDRP") {
        setBaseTokenURI("ipfs://QmNQdECHNtLLg6PAzYtC733KsyAaukFUhWT5R16H1Gxvrt/"); 
        _mint(FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 200 tokens at a time");
        for (uint i = 0; i < numberOfTokens;) {
            _safeMint(to, supply + i);
            unchecked{ i++;}           
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     * 
     */   
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit PriceChange(msg.sender, tokenPrice);
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        require(saleIsActive,"Sale NOT active yet");
        require(getSalePrice(numberOfTokens,msg.sender) <= msg.value, "Ether value sent is not correct"); 
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 3 tokens at a time");
        if (numberOfTokens<getAllowListFunds(msg.sender)){
            decreaseAddressAvailableTokens(msg.sender,numberOfTokens);
        }else{
            decreaseAddressAvailableTokens(msg.sender,getAllowListFunds(msg.sender));
        }
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens;){
            _safeMint( msg.sender, supply + i );
            unchecked{ i++;}
        }
    }

    function getSalePrice(uint256 numberOfTokens, address to) public view returns (uint256) {
        uint256 allowTokens = getAllowListFunds(to);
        if (allowTokens>numberOfTokens){
            numberOfTokens=0;
        } else {
            numberOfTokens -=  allowTokens;
            if (numberOfTokens>2){
                numberOfTokens=2;
            }
        }
        return numberOfTokens * tokenPrice;
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(owner(), address(this).balance);
    }
}
