// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SBYC contract
 * @dev Extends ERC721A - Thank you Azuki
*/

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SBYC is ERC721A, Ownable, ReentrancyGuard {

    uint        public              price           = 0.04 ether;

    uint        public              maxSupply       = 10000;
    uint        public              maxPerTx        = 50;
    
    string      public              baseURI;

    bool        public              mintEnabled;

    constructor() ERC721A("Sol Bored Yacht Club", "SBYC")
    {
    }
    
    function mint(uint256 amount) external payable 
    {
        uint cost = price;

        require(msg.sender == tx.origin,"You haven't been yourself lately.");
        require(msg.value == amount * cost,"Please send the exact amount.");
        require(totalSupply() + amount < maxSupply + 1, "No more apes left.");
        require(mintEnabled, "Minting is not live yet, hold on.");
        require(amount < maxPerTx + 1, "Max per TX reached.");

        _safeMint(msg.sender, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount < maxSupply + 1,"That's too many, even for you!");

        _safeMint(msg.sender, amount);
    }

    function toggleMint() external onlyOwner 
    {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner 
    {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner 
    {
        price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner 
    {
        maxPerTx = maxPerTx_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner 
    {
        maxSupply = maxSupply_;
    }

    function withdraw() external onlyOwner nonReentrant 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}