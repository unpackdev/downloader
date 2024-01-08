// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;


interface IWhitelist {

  event UpdateWhitelistedAddress(
    address account,
    bool isWhitelisted
  );

  /**
   * @dev Update the list of whitelisted addresses
   * @param accounts list of addresses to be updated
   * @param isWhitelisted indicate whether to add or remove from the whitelisted list
   */
  function updateWhitelistedGroup(
    address[] calldata accounts,
    bool isWhitelisted
  ) external;

  function isWhitelistedAddress(address account) external view returns (bool);
  function getWhitelistedGroup() external view returns (address[] memory accounts);
  function getWhitelistedGroupLength() external view returns (uint256 length);
  function getWhitelistedAddressAt(uint256 index) external view returns (address account);
}
