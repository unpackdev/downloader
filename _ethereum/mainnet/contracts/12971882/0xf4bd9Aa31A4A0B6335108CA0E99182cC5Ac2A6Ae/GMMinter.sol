// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GMMinter is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    uint256 private _currentTokenId = 1;
    uint256 public constant NFT_PRICE = 0.033 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant SALE_START = 1628348400;
    
    event Mint(address indexed _to, uint256 indexed _amount, uint256 indexed _firstMinted);
    
    constructor() ERC721("GM", "GM") {}
    
    function mint(uint256 amount) public payable {
        require(block.timestamp >= SALE_START, "sale has not started");
        require(amount > 0, "must mint more than 0");
        require(amount <= 30, "must mint fewer than 30");
        require(_currentTokenId <= MAX_SUPPLY, "sale has ended");
        require(_currentTokenId + amount <= MAX_SUPPLY, "exceeds max supply");
        require(amount * NFT_PRICE == msg.value, "must send correct ETH amount");
        
        uint256 firstMinted = _currentTokenId;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, _currentTokenId);
            _currentTokenId = _currentTokenId + 1;
        }
        
        emit Mint(msg.sender, amount, firstMinted);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/QmRmVobSh68d8evpu1TPNxWnxuJXZjDPYmEP8mMxXDArXE/";
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}