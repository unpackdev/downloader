// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

library MappedSinglyLinkedList {

  address public constant SENTINEL = address(0x1);

  struct Mapping {
    uint256 count;

    mapping(address => address) addressMap;
  }

  function initialize(Mapping storage self) internal {
    require(self.count == 0, "MAPPEDSINGLYLINKEDLIST: ALREADY_INIT");
    self.addressMap[SENTINEL] = SENTINEL;
  }

  function start(Mapping storage self) internal view returns (address) {
    return self.addressMap[SENTINEL];
  }

  function next(Mapping storage self, address current) internal view returns (address) {
    return self.addressMap[current];
  }

  function end(Mapping storage) internal pure returns (address) {
    return SENTINEL;
  }

  function addAddresses(Mapping storage self, address[] memory addresses) internal {
    for (uint256 i = 0; i < addresses.length; i++) {
      addAddress(self, addresses[i]);
    }
  }

  function addAddress(Mapping storage self, address newAddress) internal {
    require(newAddress != SENTINEL && newAddress != address(0), "MAPPEDSINGLYLINKEDLIST: INVALID_ADDRESS");
    require(self.addressMap[newAddress] == address(0), "MAPPEDSINGLYLINKEDLIST: ALREADY_ADDED");
    self.addressMap[newAddress] = self.addressMap[SENTINEL];
    self.addressMap[SENTINEL] = newAddress;
    self.count = self.count + 1;
  }

  function removeAddress(Mapping storage self, address prevAddress, address addr) internal {
    require(addr != SENTINEL && addr != address(0), "MAPPEDSINGLYLINKEDLIST: INVALID_ADDRESS");
    require(self.addressMap[prevAddress] == addr, "MAPPEDSINGLYLINKEDLIST: INVALID_ADDRESS");
    self.addressMap[prevAddress] = self.addressMap[addr];
    delete self.addressMap[addr];
    self.count = self.count - 1;
  }

  function contains(Mapping storage self, address addr) internal view returns (bool) {
    return addr != SENTINEL && addr != address(0) && self.addressMap[addr] != address(0);
  }

  function addressArray(Mapping storage self) internal view returns (address[] memory) {
    address[] memory array = new address[](self.count);
    uint256 count;
    address currentAddress = self.addressMap[SENTINEL];
    while (currentAddress != address(0) && currentAddress != SENTINEL) {
      array[count] = currentAddress;
      currentAddress = self.addressMap[currentAddress];
      count++;
    }
    return array;
  }

  function clearAll(Mapping storage self) internal {
    address currentAddress = self.addressMap[SENTINEL];
    while (currentAddress != address(0) && currentAddress != SENTINEL) {
      address nextAddress = self.addressMap[currentAddress];
      delete self.addressMap[currentAddress];
      currentAddress = nextAddress;
    }
    self.addressMap[SENTINEL] = SENTINEL;
    self.count = 0;
  }
}
