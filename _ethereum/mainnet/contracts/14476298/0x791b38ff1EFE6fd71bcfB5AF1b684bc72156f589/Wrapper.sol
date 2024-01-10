// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./RugPunksOrderPass.sol";

contract Mutagen111 is Ownable {
  event MutagenCooking (address indexed buyer, uint256 tokenId);
  uint256 public maxSupply = 111;
  uint256 public counter = 0;
  uint256 public endTimer;
  uint256 public tokenId; 
  uint256 private _price = 0.111 ether;
  address private _contract;
  address private _wallet;
  constructor(address contractPass, address wallet) {
    _contract = contractPass;
    _wallet = wallet;
    tokenId = RugPunksOrderPass(_contract).totalMinted();
  }

  function claim() payable external {
    require(msg.value == _price, "The price is 0.111 ETH");
    require(counter < 111, "Sold out");
    if (counter == 0) {
      endTimer = block.timestamp + 111 minutes;
    }
    if (block.timestamp > endTimer) {
      RugPunksOrderPass(_contract).renounceOwnership();
      selfdestruct(payable(_wallet));
    }
    ++counter;
    RugPunksOrderPass(_contract).safeMint(msg.sender, tokenId);
    emit MutagenCooking(msg.sender, tokenId);
    ++tokenId;
    if (counter == 111) {
      RugPunksOrderPass(_contract).renounceOwnership();
      selfdestruct(payable(_wallet));
    }
  }
}