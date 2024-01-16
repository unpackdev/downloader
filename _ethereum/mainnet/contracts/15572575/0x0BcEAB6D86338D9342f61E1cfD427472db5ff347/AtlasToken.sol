// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

// File: contracts/AtlasToken.sol

/**
 * @title AtlasToken contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract AtlasToken is
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TX = 100;
    uint256 public constant MAX_PER_ADDRESS = 100;

    // State variables
    // ------------------------------------------------------------------------
    string private _baseTokenURI;
    bool public isSaleActive = false;
    uint256 public price = 0.0001 ether;

    // Sale mappings
    // ------------------------------------------------------------------------
    mapping(address => uint256) public minted;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlySaleActive() {
        require(isSaleActive, "Sale is not active");
        _;
    }

    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "Contract caller must be externally owned account"
        );
        _;
    }

    modifier mintCompliance(uint256 numberOfTokens) {
        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_PER_TX,
            "Exceeds max per transaction"
        );
        require(
            minted[_msgSender()] + numberOfTokens <= MAX_PER_ADDRESS,
            "Exceeds per address supply"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        _;
    }

    // Constructor
    // ------------------------------------------------------------------------
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    // URI functions
    // ------------------------------------------------------------------------
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Sale switch functions
    // ------------------------------------------------------------------------
    function flipSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function mint(uint256 numberOfTokens)
        public
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlySaleActive
        mintCompliance(numberOfTokens)
    {
        minted[_msgSender()] += numberOfTokens;
        _mint(_msgSender(), numberOfTokens);
    }
}
