// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721ABurnable.sol";


contract Lunatics is Ownable, ReentrancyGuard, ERC721ABurnable {    
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    string internal baseTokenUri;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721A('Lunatics', 'KWONTOWN') {        
        maxSupply = 9999;
        maxPerWallet = 9;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner{
        baseTokenUri = baseTokenUri_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_ ), 'This Kwon is not in Kwon Town yet.');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), '.json'));
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mint(uint256 quantity_) public nonReentrant{
        uint256 totalMinted = totalSupply();
        require(totalMinted + quantity_ <= maxSupply, 'Not enough room in Kwon Town for that mint. Greed is Good.');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'Is that Kwon? Max mint reached. Greed is Good.');
        walletMints[msg.sender] = walletMints[msg.sender] + quantity_;
        _safeMint(msg.sender, quantity_);
    }

    function teamMint(uint256 quantity_) public nonReentrant{
        uint256 totalMinted = totalSupply();
        require(totalMinted + quantity_ <= maxSupply, 'Not enough room in Kwon Town for that mint. Greed is Good.');        
        walletMints[msg.sender] = walletMints[msg.sender] + quantity_;
        _safeMint(msg.sender, quantity_);
    }
}