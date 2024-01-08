// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./IWhitelist.sol";


contract Whitelist is IWhitelist, Ownable {

  using EnumerableSet for EnumerableSet.AddressSet;

  // list of whitelisted addresses
  EnumerableSet.AddressSet internal _whitelistGroup;
  // maximum number of addresses in the _whitelistGroup
  uint256 public immutable maxWhitelistSize;

  constructor(uint256 _maxWhitelistSize)  {
    maxWhitelistSize = _maxWhitelistSize;
  }

  /**
   * @dev Update the list of whitelisted addresses
   * @param accounts list of addresses to be updated
   * @param isWhitelisted indicate whether to add or remove from the whitelisted list
   */
  function updateWhitelistedGroup(
    address[] calldata accounts,
    bool isWhitelisted
  ) external override onlyOwner {
    for(uint256 i = 0; i < accounts.length; i++) {
      if (isWhitelisted && _whitelistGroup.add(accounts[i])) {
        emit UpdateWhitelistedAddress(accounts[i], true);
      } else if (!isWhitelisted && _whitelistGroup.remove(accounts[i])) {
        emit UpdateWhitelistedAddress(accounts[i], false);
      }
    }
    if (isWhitelisted) {
      // simplify by checking only in the end, only when adding new accounts
      require(_whitelistGroup.length() <= maxWhitelistSize, 'Whitelist: too many addresses');
    }
  }

  function getWhitelistedGroup() external view override returns (address[] memory accounts) {
    uint256 len = getWhitelistedGroupLength();
    accounts = new address[](len);
    for(uint256 i = 0; i < len; i++) {
      accounts[i] = getWhitelistedAddressAt(i);
    }
  }

  function isWhitelistedAddress(address account) public view override returns (bool) {
    return _whitelistGroup.contains(account);
  }

  function getWhitelistedGroupLength() public view override returns (uint256 length) {
    length = _whitelistGroup.length();
  }

  function getWhitelistedAddressAt(uint256 index) public view override returns (address account) {
    account = _whitelistGroup.at(index);
  }
}
