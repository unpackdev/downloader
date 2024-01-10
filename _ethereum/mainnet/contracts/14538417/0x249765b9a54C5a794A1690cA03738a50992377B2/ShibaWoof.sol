// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";

import "./console.sol";

contract ShibaWoof is ERC721A, Ownable {
    uint64 public constant MAX_PER_TXN = 20;
    uint256 public price = 0.0069 ether;
    uint64 public maxSupply = 5000;
    uint64 public freeMaxSupply = 500;
    bool public publicSale = true;
    string private baseURI;

    constructor(string memory baseURI_) ERC721A("ShibaWoof", "SW") {
        baseURI = baseURI_;
    }

    // public sale
    modifier publicSaleOpen() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    // public mint
    modifier insideLimits(uint256 _quantity) {
        require(totalSupply() + _quantity <= maxSupply, "Hit Limit");
        _;
    }

    modifier insideMaxPerTxn(uint256 _quantity) {
        require(_quantity > 0 && _quantity <= MAX_PER_TXN, "Over Max Per Txn");
        _;
    }

    function mint(uint256 _quantity)
        external
        payable
        publicSaleOpen
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        uint finalQuantity = _quantity;
        if (totalSupply() + _quantity > freeMaxSupply) {
            require(msg.value >= price * _quantity, "Not Enough Funds");
        }
        if (_quantity == 10 && totalSupply() + 2 < maxSupply && msg.value != 0) {
            finalQuantity += 2;
        } 
        _safeMint(msg.sender, finalQuantity);

    }

    // admin mint
    // function adminMint(address _recipient, uint256 _quantity)
    //     public
    //     onlyOwner
    //     insideLimits(_quantity)
    // {
    //     _safeMint(_recipient, _quantity);
    // }

    
    // function summon(address[] memory recipients) onlyOwner external {
    //   for (uint16 i = 0; i < recipients.length; i++) {
    //     _safeMint(recipients[i], 1);
    //   }
    // }

    // // lock total mintable supply forever
    // function decreaseTotalSupply(uint256 _total) public onlyOwner {
    //     require(_total <= maxSupply, "Over Current Max");
    //     require(_total >= totalSupply(), "Must Be Over Total");
    //     maxSupply = _total;
    // }


    function setPrice(uint256 _price)
        external
        onlyOwner
    {
        price = _price;
    }

    // function setFreeSupply(uint256 _total) public onlyOwner {
    //     require(_total <= maxSupply, "Over Current Max");
    //     require(_total >= totalSupply(), "Under Total");
    //     freeMaxSupply = _total;
    // }

    // base uri
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}