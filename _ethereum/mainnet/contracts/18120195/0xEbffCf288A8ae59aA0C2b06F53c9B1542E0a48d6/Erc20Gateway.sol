// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Erc20Gateway is Ownable {
  mapping(string => address) public symbolToAddress;
  mapping(address => string) public addressToSymbol;

  function addToken(string calldata symbol, address tokenAddress) onlyOwner external {
    require(symbolToAddress[symbol] == address(0));

    symbolToAddress[symbol] = tokenAddress;
    addressToSymbol[tokenAddress] = symbol;
  }

  function removeToken(string calldata symbol, address tokenAddress) onlyOwner external {
    require(symbolToAddress[symbol] != address(0), "Token not added");
    delete symbolToAddress[symbol];
    delete addressToSymbol[tokenAddress];
  }
}