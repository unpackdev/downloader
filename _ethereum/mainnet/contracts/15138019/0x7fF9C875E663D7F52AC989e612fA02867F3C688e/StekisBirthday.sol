// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract StekiBdayTest is ERC721A, Pausable, ReentrancyGuard, Ownable {

    uint256 public MINT_PRICE = 0.0242069 ether;
    uint256 public MAX_SUPPLY = 420;
    uint256 public MINT_LIMIT = 10;
   
    bool public saleActive = true;
    string private _baseURIextended;

    constructor() ERC721A("StekiBday", "StekQT") {}

    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "Balance is zero");
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier isPublicSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {    
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Tracking Wallet Minting Limit
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setSaleActive(bool state) external onlyOwner {
        saleActive = state;
    }

    //DEV MINT
    function devMint(uint256 numberOfTokens) external nonReentrant onlyOwner {
        // Check that minted tokens + totalSupply is less than MAX_SUPPLY
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "Not enough remaining NFTs!"
        );
        
        _safeMint(msg.sender, numberOfTokens);
    }

    //PUBLIC MINT
    function publicMint(uint256 numberOfTokens) external payable isPublicSaleActive nonReentrant {
        // Check that minted tokens + totalSupply is less than MAX_SUPPLY
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "Not enough remaining NFTs!"
        );
        // Check that minter is within total MINT_LIMIT
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "Mint Limit Reached!"
        );
        // Check if paid ether value is matches mint price
        require(msg.value == MINT_PRICE * numberOfTokens, "Incorrect amount of ether sent!");
        
        _safeMint(msg.sender, numberOfTokens);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
    {
        _beforeTokenTransfer(from, to, tokenId);
    }
}