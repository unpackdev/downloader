// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract NFTRP is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public mintPrice = 0 ether;

    bool public open = true;

    string public defaultURI = "https://www.nftrepainted.com/token/";

    uint256 public MAX_SUPPLY = 21;

    uint256 public MAX_QUANTITY = 1;

    constructor() ERC721("NFT Repainted", "NFTRP") {
        ownerMint(20);
        
        // Gift one to Mr Vitalik Buterin
        address vitalik = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
        _mintInternal(vitalik);
    }

    modifier isOpen() {
        require(open, "Contract is closed right now");
        _;
    }

    function setOpen(bool shouldOpen) external onlyOwner {
        open = shouldOpen;
    }

    function mint(uint256 quantity) public payable isOpen {
        require(quantity > 0, "Quantity must be at least 1");

        // Limit buys
        if (quantity > MAX_QUANTITY) {
            quantity = MAX_QUANTITY;
        }

        // Limit buys that exceed MAX_SUPPLY
        if (quantity + totalSupply() > MAX_SUPPLY) {
            quantity = MAX_SUPPLY - totalSupply();
        }

        uint256 price = getPrice(quantity);

        // Ensure enough ETH
        require(msg.value >= price, "Not enough ETH sent");

        for (uint256 i = 0; i < quantity; i++) {
            _mintInternal(msg.sender);
        }

        // Return any remaining ether after the buy
        uint256 remaining = msg.value - price;

        if (remaining > 0) {
            (bool success, ) = msg.sender.call{value: remaining}("");
            require(success);
        }
    }

    function getPrice(uint256 quantity) public view returns (uint256) {
        require(quantity <= MAX_SUPPLY);
        return quantity * mintPrice;
    }

    function totalSupply() public view returns (uint256) {
        // the current tokenId is the last one we have minted, so thats how many we have
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function deposit() public payable {}

    function _baseURI() internal view virtual override returns (string memory) {
        return defaultURI;
    }

    function _mintInternal(address recipient) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintInternal(msg.sender);
        }
    }

    // Set the new price in WEI
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setMaxSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function setDefaultURI(string memory newDefaultURI) public onlyOwner {
        defaultURI = newDefaultURI;
    }

    function setMaxQuantity(uint256 quantity) public onlyOwner {
        MAX_QUANTITY = quantity;
    }
}

