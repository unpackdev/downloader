/*

   ____      _          ___      ____                              ____                   
  / ___|   _| |_ ___   ( _ )    / ___|_ __ ___  ___ _ __  _   _   / ___| __ _ _ __   __ _ 
 | |  | | | | __/ _ \  / _ \/\ | |   | '__/ _ \/ _ \ '_ \| | | | | |  _ / _` | '_ \ / _` |
 | |__| |_| | ||  __/ | (_>  < | |___| | |  __/  __/ |_) | |_| | | |_| | (_| | | | | (_| |
  \____\__,_|\__\___|  \___/\/  \____|_|  \___|\___| .__/ \__, |  \____|\__,_|_| |_|\__, |
  _____               _     _        ____          |_| _  |___/                     |___/ 
 |__  /___  _ __ ___ | |__ (_) ___  | __ )  ___   ___ | |_ _   _                          
   / // _ \| '_ ` _ \| '_ \| |/ _ \ |  _ \ / _ \ / _ \| __| | | |                         
  / /| (_) | | | | | | |_) | |  __/ | |_) | (_) | (_) | |_| |_| |                         
 /____\___/|_| |_| |_|_.__/|_|\___| |____/ \___/ \___/ \__|\__, |                         
                                                           |___/                                                  

*/

/**
 * @title  Smart Contract for the Cute & Creepy Gang : Zombie Booty (airdrop)
 * @author SteelBalls
 * @notice NFT Airdrop
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

error InsufficientPayment();

contract ZombieBooty is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseTokenURI;
    uint256 public maxTokens = 666;
    uint256 public tokenReserve = 333;

    bool public publicMintActive = false;
    uint256 public publicMintPrice = 0.01 ether;
    uint256 public maxTokenPurchase = 1; 

    event EtherReceived(address sender, uint256 amount);

    // Constructor
    constructor()
        ERC721A("Cute & Creepy Gang: Zombie Booty", "ZOMBIEBOOTY")
    {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json")): "";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Mint from reserve allocation for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "RESERVE_EXCEEDED");
        require(totalSupply() + _reserveAmount <= maxTokens, "MAX_SUPPLY_EXCEEDED");

        _safeMint(_to, _reserveAmount);
        tokenReserve -= _reserveAmount;
    }

    /*
       @dev   Public mint
       @param _numberOfTokens Quantity to mint
    */
    function publicMint(uint _numberOfTokens) external payable {
        require(publicMintActive, "SALE_NOT_ACTIVE");
        require(msg.sender == tx.origin, "CALLER_CANNOT_BE_CONTRACT");
        require(_numberOfTokens <= maxTokenPurchase, "MAX_TOKENS_EXCEEDED");
        require(totalSupply() + _numberOfTokens <= maxTokens - tokenReserve, "MAX_SUPPLY_EXCEEDED");

        uint256 cost = _numberOfTokens * publicMintPrice;
        if (msg.value < cost) revert InsufficientPayment();
        
        _safeMint(msg.sender, _numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setMaxTokenPurchase(uint256 _newMaxToken) external onlyOwner {
        maxTokenPurchase = _newMaxToken;
    }

    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    function setMaxSupply(uint256 _newMax) external onlyOwner {
        require(maxTokens > totalSupply(), "Can't set below current");
        maxTokens = _newMax;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}