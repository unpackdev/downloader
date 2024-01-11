// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NSG is ERC721A, Ownable {
    uint256 public  MAX_SUPPLY = 6666;
    uint256 public  MAX_MINTS_PER_TX = 20;
    uint256 public  MAX_FREE_MINTS = 10;
    uint256 public  FREE_MINTS_PER_TX = 10;
    uint256 public  PUBLIC_SALE_PRICE = 0.0069 ether;
    uint256 public  TOTAL_FREE_MINTS = 1000;
    bool public saleIsActive = false;
    string public baseURI = "";
    mapping(address => uint) public addressFreeMintedBalance;

    constructor() ERC721A("NotSOLgods", "NSG") {}

    function mint(uint8 quantity) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");

        if (totalSupply() + quantity <= TOTAL_FREE_MINTS) {
            require(quantity > 0 && quantity <= FREE_MINTS_PER_TX, "Max free mints per transaction reached");
            require(addressFreeMintedBalance[msg.sender] + quantity <= MAX_FREE_MINTS, "Max free mint limit reached");
            addressFreeMintedBalance[msg.sender] += quantity;
        } else {
            require(quantity > 0 && quantity <= MAX_MINTS_PER_TX, "Max paid mints per transaction reached");
            require((PUBLIC_SALE_PRICE * quantity) == msg.value, "Incorrect ETH value sent");
        }

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address[] calldata addresses, uint256 quantity) external onlyOwner
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity, "");
        }
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner
    {
        baseURI = newBaseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}