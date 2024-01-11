// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NeverTooLate is ERC721A, Ownable, ReentrancyGuard { 

    uint256 public MAX_SUPPLY = 5000;
    uint256 public MINT_PRICE = 0.005 ether;
    uint256 public MAX_MINT_PER_TX = 10;

    uint256 public MAX_FREE_MINT_PER_WALLET = 2;
    uint256 public MAX_FREE_SUPPLY = 1000;

    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor(string memory initBaseURI) ERC721A("NeverTooLate", "NTL") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = MINT_PRICE;
        bool isFree = ((totalSupply() + count < MAX_FREE_SUPPLY + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= MAX_FREE_MINT_PER_WALLET)) ||
            (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < MAX_SUPPLY + 1, "Sold out!");
        require(count < MAX_MINT_PER_TX + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        MAX_FREE_SUPPLY = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}