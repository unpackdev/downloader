// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LastWords is ERC721, Ownable {

    using SafeMath for uint256;

    uint256 public _maxSupply = 5555;
    string public PROVENANCE;

    uint256 public _price = 0.04 ether;
    uint256 public _maxMintCount = 20;
    bool public _saleIsActive = false;

    constructor() ERC721("last words.", "LASTWORD") { }

    function mint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(_saleIsActive, "Sale not active");
        require(mintCount <= _maxMintCount, "Max mint count exceeded");
        require(supply + mintCount < _maxSupply, "Max token supply exceeded");
        require(msg.value >= _price * mintCount, "Insufficient payment value");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function reserveTokens(uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }
    
    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        PROVENANCE = _provenance;
    }

    function flipSale() public onlyOwner {
        if(_saleIsActive) _saleIsActive = false;
        else _saleIsActive = true;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}