// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Common.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract INCEPTIONPASSCollective is ERC721Common, ReentrancyGuard {
    using Strings for uint256;

    bool public saleActive;
    uint8 public constant MAX_STANDARD_MINT = 2;
    uint8 public constant MAX_GOLD_MINT = 5;
    uint16 public _standardTokenIdTracker;
    uint16 public _goldTokenIdTracker;
    uint16 public constant MAX_ITEMS = 5_000;
    uint16 public constant MAX_STANDARD_ITEMS = 4_500;
    uint16 public constant MAX_GOLD_ITEMS = 500;
    uint256 public STANDARD_PRICE = 0.02 ether;
    uint256 public GOLD_PRICE = 0.08 ether;

    address constant w1 = 0x79792bF612bf456ff9ED70F5016C1c01Ee9c7598;
    address constant w2 = 0xDE4CD210246271a3595870cE5442298550C0a263;

    constructor(
        string memory name,
        string memory symbol
    )
        ERC721Common(name, symbol)
    {}

    function standardMint(address _to, uint16 _count) public payable 
        nonReentrant
        whenNotPaused {
        require(saleActive == true, "Sale has not yet started");
        require(_standardTokenIdTracker + _count <= MAX_STANDARD_ITEMS, "Max limit");
        require(_count <= MAX_STANDARD_MINT, "Exceeds number");
        if(_standardTokenIdTracker > 2500) require(msg.value >= STANDARD_PRICE * _count, "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            uint16 id = _standardTokenIdTracker;
            _standardTokenIdTracker++;
            _safeMint(_to, id);
        }
    }

    function goldMint(address _to, uint16 _count) public payable 
        nonReentrant
        whenNotPaused {
        require(saleActive == true, "Sale has not yet started");
        require(_goldTokenIdTracker + _count <= MAX_GOLD_ITEMS, "Max limit");
        require(_count <= MAX_GOLD_MINT, "Exceeds number");
        require(msg.value >= GOLD_PRICE * _count, "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            uint16 id = MAX_STANDARD_ITEMS + _goldTokenIdTracker;
            _goldTokenIdTracker++;
            _safeMint(_to, id);
        }
    }

    function setSaleStatus(bool _status) external onlyOwner {
        saleActive = _status;
    }

    function setStandardPrice(uint256 _price) external onlyOwner {
        STANDARD_PRICE = _price;
    }

    function setGoldPrice(uint256 _price) external onlyOwner {
        GOLD_PRICE = _price;
    }

    /// @notice Prefix for tokenURI return values.
    string public baseTokenURI;

    /// @notice Set the baseTokenURI.
    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /// @notice Returns the token's metadata URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : "";
    }

    /**
    @notice Returns total number of existing tokens.
    @dev Using ERC721Enumerable is unnecessarily expensive wrt gas. However
    Etherscan uses totalSupply() so we provide it here.
     */
    function totalSupply() external view returns (uint256) {
        return _goldTokenIdTracker + _standardTokenIdTracker;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(w1, balance * 80 / 100);
        _widthdraw(w2, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
    }
}