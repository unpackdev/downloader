// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

// created by OddWorlds Labs << https://www.oddworlds.io >>
contract OddWorlds is ERC721URIStorage, Ownable {
    // counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // max worlds to be generated
    uint256 public constant maxWorlds = 5555;

    // worlds price
    uint256 public unitWorldsPrice;

    // pre-sale vars
    uint256 public maxWorldsPreSale = 555;
    uint256 public unitWorldsPreSale;
    uint256 public unitWorldsPricePreSale;
    enum preSaleStatus {
        CLOSED,
        OPEN,
        FINISHED
    }
    preSaleStatus preSale;
    mapping(address => uint256) internal _preSaleList;

    mapping(uint256 => uint256) internal _genes;

    // events
    event OddWorldsTokenMinted(uint256 indexed newItemId, uint256 gene);
    event OddWorldsPriceChanged(uint256 newUnitWorldsPrice);
    event OddWorldsPreSalePriceChanged(uint256 newUnitWorldsPricePreSale);
    event OddWorldsMaxWorldsPreSaleChanged(uint256 newMaxWorldsPreSale);

    constructor() ERC721("ODDWORLDS", "OWS") {
        // Just for pre-sale
        unitWorldsPreSale = 0;
        unitWorldsPricePreSale = 70000000000000000 wei; // 0.07 eth
        unitWorldsPrice = 80000000000000000 wei; // 0.08 eth
        preSale = preSaleStatus.CLOSED;
    }

    // mint - owner
    function mintByOwner(address recipient) public onlyOwner returns (bool) {
        require(_tokenIds.current() <= maxWorlds, "Total supply reached");
        commonMint(recipient);
        return true;
    }

    // mint - pre sale
    function mintPreSale(uint256 amount) public payable returns (bool) {
        require(uint256(preSale) == 1, "pre-sale should be opened");
        require(msg.value == amount);
        require(amount == unitWorldsPricePreSale, "Wrong price per world desired");
        require(_preSaleList[_msgSender()] != 1, "Already buyed in this pre sale, sorry");

        unitWorldsPreSale++;

        // close pre-sale
        if (unitWorldsPreSale == maxWorldsPreSale) {
            preSale = preSaleStatus.FINISHED;
        }

        _preSaleList[_msgSender()] = 1;
        commonMint(_msgSender());

        return true;
    }

    // mint
    function mint(uint256 amount) public payable returns (bool) {
        require(uint256(preSale) == 2, "Pre-sale should be closed");
        require(msg.value == amount);
        require(amount == unitWorldsPrice, "Wrong price per world desired");
        require(_tokenIds.current() <= maxWorlds, "Total supply reached");

        commonMint(_msgSender());

        return true;
    }

    // common utility for mint
    function commonMint(address sender) internal {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(sender, newItemId);
        uint256 gene = random(newItemId);
        _genes[newItemId] = gene;

        emit OddWorldsTokenMinted(newItemId, gene);
    }

    // return minted counter
    function getCountTokenMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    // get random gene by tokenId
    function random(uint256 tokenId) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        tokenId,
                        blockhash(block.number),
                        blockhash(block.number - tokenId)
                    )
                )
            );
    }

    // set price
    function setUnitWorldsPrice(uint256 newUnitWorldsPrice) public onlyOwner {
        unitWorldsPrice = newUnitWorldsPrice;
        emit OddWorldsPriceChanged(newUnitWorldsPrice);
    }

    // set pre-sale price
    function setUnitWorldsPricePreSale(uint256 newUnitWorldsPricePreSale) public onlyOwner {
        unitWorldsPricePreSale = newUnitWorldsPricePreSale;
        emit OddWorldsPreSalePriceChanged(newUnitWorldsPricePreSale);
    }

    // set max worlds pre-sale price
    function setMaxWorldsPreSale(uint256 newMaxWorldsPreSale) public onlyOwner {
        maxWorldsPreSale = newMaxWorldsPreSale;
        emit OddWorldsMaxWorldsPreSaleChanged(newMaxWorldsPreSale);
    }

    // set token url generated
    function setBaseURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    // check your gene token
    function geneOf(uint256 tokenId) public view returns (uint256 gene) {
        return _genes[tokenId];
    }

    // withdraw balance to owner
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // get contract balance
    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // set pre-sale status
    function setPreSaleStatus(uint256 status) public onlyOwner {
        require(uint256(status) >= 0 && uint256(status) <= 2,"bad pre sale status");
        if (status == 0) {
            preSale = preSaleStatus.CLOSED;
        } else if (status == 1) {
            preSale = preSaleStatus.OPEN;
        } else if (status == 2) {
            preSale = preSaleStatus.FINISHED;
        }
    }

    // get pre-sale status
    function getPreSaleStatus() public view returns (string memory) {
        if (uint256(preSale) == 0) {
            return "CLOSED";
        } else if (uint256(preSale) == 1) {
            return "OPEN";
        } else {
            return "FINISHED";
        }
    }
}

