// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract TreasureWorld is ERC1155Supply, Ownable {
  string public name;
  string public symbol;

  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 1000;
  uint256 public fixedMintAmount = 1;
  uint256 public fixedId = 1;

  bool public saleStatus = false;

  mapping(address => bool) public mintedStatus;

  mapping(uint256 => string) public tokenURI;

  constructor() ERC1155("") {
    name = "Treasure World";
    symbol = "TRSR";
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "cannot be called by a contract");
    _;
  }
  //

  // ======= View =======
  function _totalSupply() public view returns(uint256){
    return totalSupply(fixedId);
  }
  //

  // ====== Public ======
  function mint() public payable callerIsUser {
    // Is sale active
    require(saleStatus, "sale is not active");
    //

    // Amount controls
    uint256 supply = _totalSupply();
    require(supply + fixedMintAmount <= maxSupply, "max NFT limit exceeded");

    require(!mintedStatus[msg.sender], "max NFT limit exceeded per wallet");
    //

    // Payment control
    require(msg.value >= cost * fixedMintAmount, "insufficient funds");
    //

    // Change minted status before mint
    mintedStatus[msg.sender] = true;
    //

    _mint(msg.sender, fixedId, fixedMintAmount, "");
  }

  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = _totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _mint(_to, fixedId, _mintAmount, "");
  }

  // ====== Only Owner ======
  // Cost
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  //

  // Metadata
  function setURI(uint _id, string memory _uri) public onlyOwner {
    tokenURI[_id] = _uri;
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
  //

  // Sale state
  function setSaleStatus() public onlyOwner {
    saleStatus = !saleStatus;
  }
  //

  // Withdraw Funds
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}