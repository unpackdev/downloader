// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Slowths is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0.002 ether;
    uint256 public constant MAX_FREE_MINT = 1;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant MAX_TEAM_MINT = 100;

    constructor() ERC721A("Slowths", "SLOWTHS") {}

    /**
     * Public sale mechansim
     */
    bool public publicSale = false;


    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    /**
     * Public minting
     */
    mapping(address => uint256) public publicAddressMintCount;

    function mintPublic(uint256 _quantity) public payable {
        require(totalSupply() + _quantity + MAX_TEAM_MINT <= MAX_SUPPLY, "Surpasses supply");
        require(publicSale, "Public sale not started");
        require(_quantity > 0 && publicAddressMintCount[msg.sender] + _quantity <= MAX_PER_WALLET,"Minting above public limit");
         if (publicAddressMintCount[msg.sender] >= MAX_FREE_MINT) {
            require(msg.value >= _quantity * MINT_PRICE, "Insufficient funds");
        } 
         else if (_quantity <= MAX_FREE_MINT - publicAddressMintCount[msg.sender]) {
            require(msg.value >= 0);
        }
        else {
            require(msg.value >= (_quantity - MAX_FREE_MINT + publicAddressMintCount[msg.sender]) * MINT_PRICE, "Insufficient funds");
        }
        publicAddressMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * Team minting
     */
    uint256 public _teamMinted;

    function devMint(address to, uint256 _quantity) external onlyOwner {
        require (_teamMinted <= MAX_TEAM_MINT, "Exceed max supply");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        _teamMinted += _quantity;
        _safeMint(to, _quantity);
    }

    /**
     * Base URI
     */
    string private baseURI = "";

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}