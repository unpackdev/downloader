// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPriceOracle {
  error ERC20NotPriced(address payERC20);

  function erc20Price(
    string memory name,
    uint256 tokenId,
    address payERC20
  ) external view returns (uint256);

  function nativePrice(
    string memory name,
    uint256 tokenId
  ) external view returns (uint256);

  function priceList(
    string memory name,
    uint256 tokenId,
    address[] memory payERC20s
  ) external view returns (uint256[] memory, uint256);
}
