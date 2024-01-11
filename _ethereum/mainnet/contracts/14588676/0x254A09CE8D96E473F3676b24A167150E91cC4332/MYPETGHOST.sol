// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";

import "./console.sol";

contract MYPETGHOST is ERC721A, Ownable {
    uint64 public constant MAX_PER_TXN = 20;
    uint256 public price = 0.005 ether;
    uint64 public maxSupply = 5000;
    uint64 public freeMaxSupply = 500;
    // bool public publicSale = true;
    string private baseURI;

    constructor(string memory baseURI_) ERC721A("My Pet Ghost", "MPG") {
        baseURI = baseURI_;
    }

    // public sale
    // modifier publicSaleOpen() {
    //     require(publicSale, "Public Sale Not Started");
    //     _;
    // }

    // function togglePublicSale() external onlyOwner {
    //     publicSale = !publicSale;
    // }

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
        // publicSaleOpen
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        if (totalSupply() + _quantity > freeMaxSupply) {
            require(msg.value >= price * _quantity, "Not Enough Funds");
        }
        _safeMint(msg.sender, _quantity);

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

    // function setApprovalForAll(address operator, bool approved) public onlyOwner override {
    //     super.setApprovalForAll(operator, approved);
    // }

    //     /**
    //  * @dev See {IERC165-royaltyInfo}.
    //  */
    // function royaltyInfo(uint256 tokenId, uint256 salePrice)
    //     external
    //     view
    //     override
    //     returns (address receiver, uint256 royaltyAmount)
    // {
    //     require(_exists(tokenId), "Nonexistent token");

    //     return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    // }
}