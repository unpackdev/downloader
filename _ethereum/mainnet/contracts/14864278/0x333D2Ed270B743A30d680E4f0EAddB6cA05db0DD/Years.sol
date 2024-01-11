// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AA.sol";
import "./EnumerableSet.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
Deploying contracts with the account: 0xe725D38CC421dF145fEFf6eB9Ec31602f95D8097
Account balance: 4956039708177725078
Token address: 0xDAb18F402FFab153F1e73fCc912938801B7D9206
 */
 
contract Years is ERC721AA, Ownable{

  uint256 public constant TOTAL_SUPPLY = 10000;

  constructor(string memory baseuri_) ERC721AA("10000 Years", "Years", baseuri_) {
  }

  function teamMintFor(address recipient, uint amount) external onlyOwner {
    require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceed max supply");
    _safeMint(recipient, amount);
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _baseuri = uri;
  }

}