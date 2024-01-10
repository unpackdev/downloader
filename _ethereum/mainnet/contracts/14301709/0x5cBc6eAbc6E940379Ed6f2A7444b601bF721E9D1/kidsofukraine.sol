// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract KidsOfUkraine is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public tokenSupply;

    bool public mintIsActive = false;
    uint256 public maxSupply = 9999;
    uint256 public mintPrice = 10000000000000000; // 0.01 ETH
    address public charityWallet = 0xba9e013c5f6cbcb698638c35C933B3ddBd3698C2;

    string public _baseTokenURI = "ipfs://QmTJ2GNNLLMJJw8a2wbPBLdNapVXnzZzPu2MyMnUj4xxCb/";
    mapping(uint256 => bool) public isGolden;

    // constructor
    constructor() ERC721("KidsOfUkraine", "KidsOfUkraine") {}

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setMintCost(uint256 _newPrice) external onlyOwner() {
        mintPrice = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner() {
        maxSupply = _maxSupply;
    }

    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(charityWallet).transfer(balance);
    }

    // mint
    function devMint(uint256 numberOfTokens) public onlyOwner {
        uint256 supply = tokenSupply.current() + 1;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint() external payable  {
        require(mintIsActive, "Mint is not active");
        require(mintPrice <= msg.value, "ETH sent must be more than 0.01eth");
        require(tokenSupply.current() + 1 <= maxSupply, "maxSupply is reached");
        
        uint256 supply = tokenSupply.current() + 1;
        
        tokenSupply.increment();
        if (msg.value >= 500000000000000000) {
            isGolden[supply] = true;
        }
        _safeMint(msg.sender, supply);    
    }
}
