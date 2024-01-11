//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BlueChipTrackerPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    uint256 public MAX_MINTS = 4;
    uint256 public MINT_PRICE = 0.025 ether;
    uint256 public TOTAL_SUPPLY = 2048;

    bool public whitelistSaleActive = true;

    mapping(address => bool) public whitelistMembers;

    constructor(address[] memory _whitelistMembers) ERC721("BlueChip Tracker Pass", "BCTP") {
        for (uint i = 0; i < _whitelistMembers.length; i++) {
            whitelistMembers[_whitelistMembers[i]] = true;
        }
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "ipfs://bafybeifscf2it4fdhud5zg5euvr5mou3orpocegqtzy7xudolpyae42pgy/";
    }

    function mint(uint _quantity) external payable {
        require(!whitelistSaleActive, "Whitelist is enabled");
        require(msg.value >= MINT_PRICE * _quantity, "Insufficient ETH amount");
        require(_quantity <= MAX_MINTS, "Max mint per TX reached");
        require(tokenIdCounter.current() + _quantity <= TOTAL_SUPPLY, "Reached total supply");

        for (uint i; i < _quantity; i++) {
            tokenIdCounter.increment();
            uint256 tokenId = tokenIdCounter.current();
            _mint(msg.sender, tokenId);
        }
    }

    function whitelistMint() external {
        require(whitelistSaleActive, "Whitelist minting disabled");
        require(whitelistMembers[msg.sender], "Not whitelisted");

        whitelistMembers[msg.sender] = false;

        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _mint(msg.sender, tokenId);
    }

    function ownerMint(address to, uint _quantity) external onlyOwner {
        require(tokenIdCounter.current() + _quantity <= TOTAL_SUPPLY, "Reached total supply");

        for (uint i; i < _quantity; i++) {
            tokenIdCounter.increment();
            uint256 tokenId = tokenIdCounter.current();
            _mint(to, tokenId);
        }
    }

    function flipWhitelistSaleActive() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function withdraw(address _to, uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Not enough ETH in the contract");
        (bool success,) = _to.call{value : _amount}("");
        require(success, "Failed to send Ether");
    }
}
