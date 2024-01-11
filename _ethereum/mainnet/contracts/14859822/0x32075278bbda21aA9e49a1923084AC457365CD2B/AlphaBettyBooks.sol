// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./AlphaBettyDoodlesI.sol";

//          ,--.     ,--.           ,--.          ,--.   ,--.             
//     ,--,--|  |,---.|  ,---. ,--,--|  |-. ,---.,-'  '-,-'  '-,--. ,--.   
//    ' ,-.  |  | .-. |  .-.  ' ,-.  | .-. | .-. '-.  .-'-.  .-'\  '  /    
//    \ '-'  |  | '-' |  | |  \ '-'  | `-' \   --. |  |   |  |   \   '     
//     `--`--`--|  |-'`--' `--'`--`--'`---' `----' `--'   `--' .-'  /      
//              `--'                                           `---'       
//    ,--.              ,--.        ,--.                         ,--.      
//    |  |-. ,---. ,---.|  |,-.     |  |,--,--,--.,--,--,--, ,---|  ,---.  
//    | .-. | .-. | .-. |     /     |  ' ,-.  |  ||  |      | .--|  .-.  | 
//    | `-' ' '-' ' '-' |  \  \     |  \ '-'  '  ''  |  ||  \ `--|  | |  | 
//     `---' `---' `---'`--'`--'    `--'`--`--'`----'`--''--'`---`--' `--' 

contract AlphaBettyBooks is ERC1155Supply, Ownable, ReentrancyGuard {

    string collectionURI = "ipfs://QmUydpHhkpDGFxjgZrLYdJD7VivMxhhsd2ThZqVYuy6UKe/";
    string private name_;
    string private symbol_; 
    uint256 public tokenPrice;
    uint256 public tokenQty;
    uint256 public maxMintQty;
    uint256 public maxWalletQty;
    uint256 public maxTokenId;
    bool public paused;

    AlphaBettyDoodlesI public bettyCollection;


    constructor() ERC1155(collectionURI) {
        name_ = "AlphaBetty Books";
        symbol_ = "ABB";
        tokenPrice = 0.01 ether;
        tokenQty = 50;
        maxMintQty = 2;
        maxWalletQty = 2;
        maxTokenId = 3;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    function mint(uint256 id, uint256 amount)
        public
        payable
        nonReentrant
    {
        require(paused == false, "Minting is paused");
        require(bettyCollection.balanceOf(_msgSender()) > 0, "You must own an AlphaBetty NFT to mint.");
        require(amount <= maxMintQty, "Mint quantity is too high");
        require(this.balanceOf(_msgSender(), id) + amount <= maxWalletQty, "You have hit the max tokens per wallet");
        require(totalSupply(id) < tokenQty, "All Minted");
        require(id <= maxTokenId, "That token has not been published yet."); 
        require(amount * tokenPrice == msg.value, "You have not sent the correct amount of ETH");
        require(tx.origin == _msgSender(), "The caller is another contract");

        _mint(_msgSender(), id, amount, "");
    }

    //=============================================================================
    // Admin Functions
    //=============================================================================

    function setBettyCollection(address _contract) external onlyOwner {
        bettyCollection = AlphaBettyDoodlesI(_contract);
    }

    function adminMintOverride(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function setCollectionURI(string memory newCollectionURI) public onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setTokenQty(uint256 qty) public onlyOwner {
        tokenQty = qty;
    }

    function setMaxMintQty(uint256 qty) public onlyOwner {
        maxMintQty = qty;
    }

    function setMaxWalletQty(uint256 qty) public onlyOwner {
        maxWalletQty = qty;
    }

    function setMaxTokenId(uint256 id) public onlyOwner {
        maxTokenId = id;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function withdrawETH() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //=============================================================================
    // Override Functions
    //=============================================================================
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(collectionURI, Strings.toString(_tokenId), ".json"));
    }    
}
