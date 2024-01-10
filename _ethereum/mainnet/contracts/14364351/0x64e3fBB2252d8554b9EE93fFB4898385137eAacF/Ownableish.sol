// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error NotOwner();

abstract contract Ownableish {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    if (msg.sender != _owner) revert NotOwner();
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    _owner = _newOwner;
  }

  function renounceOwnership() public onlyOwner {
    _owner = address(0);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
  }
}
