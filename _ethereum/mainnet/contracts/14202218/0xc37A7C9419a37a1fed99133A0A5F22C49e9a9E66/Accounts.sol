//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Accounts {
  mapping(address => address) public accounts;
  uint256 public size;
  address public constant HEAD = address(1);

  constructor() {
    accounts[HEAD] = HEAD;
  }

  function isStaking(address account) public view returns (bool) {
    return accounts[account] != address(0);
  }

  function add(address account) public {
    require(!isStaking(account), "Adding existing account");
    accounts[account] = accounts[HEAD];
    accounts[HEAD] = account;
    size += 1;
  }

  function remove(address account) public {
    require(isStaking(account), "Removing non-existing account");
    address previousAccount = getPrevious(account);
    accounts[previousAccount] = accounts[account];
    accounts[account] = address(0);
    size -= 1;
  }

  function getFirst() public view returns (address) {
    return accounts[HEAD];
  }

  function getNext(address account) public view returns (address) {
    return accounts[account];
  }

  function getPrevious(address account) internal view returns (address) {
    address currentAccount = HEAD;
    while (accounts[currentAccount] != HEAD) {
      if (accounts[currentAccount] == account) {
        return currentAccount;
      }
      currentAccount = accounts[currentAccount];
    }

    return address(0);
  }

  function getAll() public view returns (address[] memory) {
    address[] memory addresses = new address[](size);

    address currentAccount = HEAD;
    uint256 index;
    while (accounts[currentAccount] != HEAD) {
      addresses[index] = accounts[currentAccount];
      currentAccount = accounts[currentAccount];
      index += 1;
    }

    return addresses;
  }
}
