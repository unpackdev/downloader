// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";

import "./console.sol";

//    ____  __               ____  _          __    
//   / __ \/ /______ ___  __/ __ )(_)________/ /____
//  / / / / //_/ __ `/ / / / __  / / ___/ __  / ___/
// / /_/ / ,< / /_/ / /_/ / /_/ / / /  / /_/ (__  ) 
// \____/_/|_|\__,_/\__, /_____/_/_/   \__,_/____/  
//                 /____/                           

contract OkayBirds is ERC721A {
    uint64 public constant MAX_PER_TXN = 20;
    uint256 public price = 0.0069 ether;
    uint64 public maxSupply = 6969;
    uint64 public freeMaxSupply = 1000;
    string private baseURI;

    constructor(string memory baseURI_) ERC721A("OkayBirds", "OKB") {
        baseURI = baseURI_;
    }

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
        // publicSaleOpen
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        if (totalSupply() + _quantity > freeMaxSupply) {
            require(msg.value >= price * _quantity, "Not Enough Funds");
        }
        _safeMint(msg.sender, _quantity);

    }

    function freemint(uint256 _quantity)
        external
        payable
        // publicSaleOpen
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        require(_quantity > 0 && _quantity <= 2, "Over Max Per Txn");
        require(totalSupply() + _quantity <= freeMaxSupply);
        require(_quantity > 0 && _quantity <= MAX_PER_TXN, "Over Max Per Txn");
        _safeMint(msg.sender, _quantity);

    }

    function setPrice(uint256 _price)
        external
        onlyOwner
    {
        price = _price;
    }

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