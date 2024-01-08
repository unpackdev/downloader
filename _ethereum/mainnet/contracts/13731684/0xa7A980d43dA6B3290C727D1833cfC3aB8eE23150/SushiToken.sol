// // SPDX-License-Identifier: MIT

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

                                                                  

contract SushiToken is ERC1155, Ownable {
  using Strings for uint256;


  constructor() public ERC1155("https://gateway.pinata.cloud/ipfs/QmdwzuJ2VvM3ZhPZas9VYsUsM1FLeyDB9kRsUj8bTLbgXc/{id}") {}


  function withdraw() external onlyOwner {
      msg.sender.transfer(address(this).balance);
  }


  function batchMint(uint256 _id, address[] calldata _addresses, uint256[] calldata _qty) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
        require(_addresses[i] != address(0), "Can't add the null address");

        _mint(_addresses[i], _id, _qty[i], "");
    }
  }

  function setURI(string calldata _uri) external onlyOwner {
    _setURI(_uri);
  }
}