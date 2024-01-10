//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract gfers is ERC721Enumerable, Ownable {
    using Address for address;
    
    // Max Supply
    uint256 constant MAX_SUPPLY = 5000;

    // Max Free
    uint256 constant MAX_FREE = 1000;

    // Max allocaiton per wallet
    uint256 constant WALLET_MAX = 20;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "https://gfers.art/api/nft/";

    // Starting and stopping sale
    bool public saleActive = false;
    
    // Price of each token
    uint256 public price = 0.012 ether;

    // NFTs per wallet record
    mapping(address => uint256) public walletMinted;

    constructor () ERC721 ("gfers", "gfers") {}

    // Mint a free NFT
    function free(uint256 _amount) public {
        require(saleActive, "sale_is_closed");
        require(_amount <= WALLET_MAX, "exceeded_max_mint_amount");
        require(walletMinted[msg.sender] <= WALLET_MAX , "exceeded_max_per_wallet");
        require(totalSupply() + _amount <= MAX_FREE, "exceeded_max_free");
        require(totalSupply() + _amount <= MAX_SUPPLY, "out_of_stock");

        for(uint256 i; i < _amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
            walletMinted[msg.sender]++;
        }
    }

    // Mint an NFT
    function mint(uint256 _amount) public payable {
        require(saleActive, "sale_is_closed");
        require(_amount <= WALLET_MAX, "exceeded_max_mint_amount");
        require(walletMinted[msg.sender] <= WALLET_MAX , "exceeded_max_per_wallet");
        require(totalSupply() + _amount <= MAX_SUPPLY, "out_of_stock");
        require(msg.value == price * _amount, "insufficient_eth");

        for(uint256 i; i < _amount; i++){
            _safeMint(msg.sender, totalSupply() + 1);
            walletMinted[msg.sender]++;
        }
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // State Management //
    // Start and stop sale
    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

    // Set new baseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    // Withdraw funds from contract for the team
    function withdrawTeam() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
