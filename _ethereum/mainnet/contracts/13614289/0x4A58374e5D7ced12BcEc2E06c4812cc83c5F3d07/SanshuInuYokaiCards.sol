// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC1155Tradable.sol";

contract SanshuInuYokaiCards is ERC1155Tradable {
  constructor(address _proxyRegistryAddress)
    ERC1155Tradable(
      'Sanshu INU Limited Edition Yokai Cards',
      'SIYC',
      'https://dogpark.sanshuinufinance.com/api/yokaicards/',
      _proxyRegistryAddress
    )
  {}
}
