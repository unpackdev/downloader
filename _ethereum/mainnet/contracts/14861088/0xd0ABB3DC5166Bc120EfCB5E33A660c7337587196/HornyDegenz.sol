// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract HornyDegenz is ERC721A, Ownable, ReentrancyGuard {

    uint256 public constant PRICE = 69000000000000000; //0.069 ETH
    uint256 public constant MAX_DEGENZ = 6969; 
    uint256 public constant MAX_PURCHASE = 20;

    bool public saleIsActive; 

    string private _baseTokenURI;

    address private constant HD = 0x7794b27b8CAFD424E3eD32663AfE0B74A535C0bA;
    address private constant DEV = 0x409BE643159f7c69394c0a944081E7cD2592cE33;
    
    constructor(string memory baseURI) ERC721A("Horny Degenz", "HORNYDEGENZ") {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Minting not active");
        require(quantity <= MAX_PURCHASE, "Exceeds max per transaction");
        require(totalSupply() + quantity <= MAX_DEGENZ, "Exceeds max degenz");
        require(quantity * PRICE <= msg.value, "Not enough funds provided");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 bal = address(this).balance / 100;
        (bool success1, ) = DEV.call{value: bal * 10 }("");
        (bool success2, ) = HD.call{value: bal * 90 }("");
        require(success1, "DEV transfer failed.");
        require(success2, "HD transfer failed.");
    }

    // contract can recieve Ether
    fallback() external payable {}
    receive() external payable {}
}