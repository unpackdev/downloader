// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IRueArcanaToken.sol";

contract RueArcanaMinter is Ownable, ReentrancyGuard {

    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    uint256 public constant TOKEN_COST = 0.05 ether;

    bool public saleIsActive = false;
    uint256 public publicSaleStart; 

    mapping(address => uint256) private addressToMintCount;

    IRueArcanaToken public token;

    constructor(address nftAddress,
                uint256 publicSaleStartTimestamp,
                uint256 tokenSupply,
                uint256 maxMintsAddress) {
        token = IRueArcanaToken(nftAddress);
        publicSaleStart = publicSaleStartTimestamp;
        maxTokens = tokenSupply;
        maxMintsPerAddress = maxMintsAddress;
    }
    
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && saleIsActive;
    }

    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = token.tokenCount();

        require(saleIsActive, "Sale is not active");

        require(block.timestamp >= publicSaleStart, "Sale has not commenced");

        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");

        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Cannont exceed this many tokens per tx");

        require(msg.value >= TOKEN_COST * amount, "ETH amount sent is not correct");

        require(supply + amount <= maxTokens, "More than max token supply");

        token.mint(amount, msg.sender);

        addressToMintCount[msg.sender] += amount;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}
