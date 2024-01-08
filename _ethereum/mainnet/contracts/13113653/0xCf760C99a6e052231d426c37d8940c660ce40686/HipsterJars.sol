// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract HipsterJars is ERC721, ERC721Enumerable, Ownable {
    string private _currentBaseURI;
    
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;
    uint256 private price = 30000000000000000; // 0.03 Ether
    uint256 private startSales = 1630958400000; // 2021-09-06 20:00:00

    constructor() ERC721("Hipster Jars", "JAR")
    {
      setBaseURI("https://ipfs.io/ipfs/Qmf5R2Vjwje7UoSfWcvP4izE1dHRsKL8xWteZiJyN9QWa2/");
      
      mint(8);
    }

    function setStartSales(uint _start) public onlyOwner {
        startSales = _start;
    }

    function getStartSales() public view returns(uint) {
        return startSales;
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_TOKENS, "Sale end.");
        if (_msgSender() != owner()) {
            require(block.timestamp >= startSales, "Sales not open.");
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function mint(uint256 _count) internal
    {
        uint256 totalSupply = totalSupply();

        require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function claim(uint256 _count) public payable saleIsOpen {
        require(msg.value >= (price * _count), "Ether value sent is not correct");
        
        mint(_count);
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
