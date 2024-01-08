// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract RareFolk is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MAX_MINT_AMOUNT = 10;
    uint256 public constant PRICE = 0.04 ether;

    uint256 public reserved = 200;
    bool public paused = true;

    string _baseTokenURI;
    address immutable _proxyRegistryAddress;

    uint256 _nextTokenId = 0;

    constructor(address proxyRegistryAddress) ERC721("Rare Folk", "RAREFOLK") {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function mint(uint256 amount) public payable {
        require(!paused, "Sale paused");
        require(amount <= MAX_MINT_AMOUNT, "Mint amount exceeds maximum");
        require(
            _nextTokenId + amount <= MAX_SUPPLY - reserved,
            "Not enough tokens remaining"
        );
        require(msg.value >= PRICE * amount, "Not enough value sent");

        _mintAmount(amount, _nextTokenId);
    }

    function mintReserved(uint256 amount) external onlyOwner {
        require(amount <= reserved, "Not enough reserved tokens remaining");

        _mintAmount(amount, _nextTokenId);
        reserved -= amount;
    }

    function _mintAmount(uint256 amount, uint256 startId) internal {
        _nextTokenId += amount;
        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, startId + i);
        }
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    function pause(bool value) external onlyOwner {
        paused = value;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => address) public proxies;
}
