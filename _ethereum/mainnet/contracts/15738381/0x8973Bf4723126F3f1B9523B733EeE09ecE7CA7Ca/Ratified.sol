// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


pragma solidity ^0.8.7;

contract RatifiedAI is Ownable, ERC721A {

    address artist = 0xcc7059EdC94CFc44eD3C102Ba5178063CFd1447B;
    uint256 public price = 0.009 ether;
    uint256 public max_supply = 666;
    bool public sewers = true;

    string private baseurl;

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("RATIFIED", "RTFAI") {


    }

    function mint(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= price * _quantity, "NO MONEY");
                require(max_supply >= totalSupply() + _quantity,"SOLD OUT");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= 3,"ONLY 3 PER ADDRESS MAX");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function LetRatsOut() public onlyOwner {
        sewers = !sewers;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseurl = baseURI;
    }



    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1),".json")) : '';
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseurl;
    }
    
    function withdraw() public payable onlyOwner {

    (bool hs, ) = payable(artist).call{value: address(this).balance * 50 / 100}("");
    require(hs);
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
        modifier mintCompliance() {
        require(!sewers, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

}
