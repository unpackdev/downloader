// SPDX-License-Identifier: NONE


pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract CentauriGuardian is ERC721Enumerable, Ownable {
    
    using Strings for uint256;
    
    uint256 public price = 80000000000000000; // 0.08 ETH
    uint256 public maxSupply = 10042;
    uint256 public reserve = 100;
    uint256 public maxMintAmount = 20;

    bool public saleIsActive = false;

 constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
     mintToOwner(20);
  }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmYQvHL65iUSdweYUYNSHqX2exGoUSn3zJybB5pLbvPf4U/";
    }
    
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!saleIsActive);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value >= price * _mintAmount);

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

    function mintToOwner(uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0 && numberOfTokens <= reserve);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex + 1);
        }

        reserve = reserve - numberOfTokens;
    }

  function setCost(uint256 _newCost) public onlyOwner() {
    price = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function pause(bool _state) public onlyOwner {
    saleIsActive = _state;
  }
 

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

}