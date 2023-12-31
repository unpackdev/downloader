// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721Collection.sol";

contract ERC721Deployer {
  event ContractDeployedERC721(address indexed contractAddress , address indexed owner , string name , string symbol, uint96 royaltyFee);
  constructor(){
  }
  function deploy(string memory name , string memory symbol ,  uint96 royaltyFee) external {
       ERC721Collection erc721 = new ERC721Collection(name , symbol, royaltyFee, msg.sender);
       emit ContractDeployedERC721(address(erc721) , msg.sender , name, symbol, royaltyFee);
  }

}
