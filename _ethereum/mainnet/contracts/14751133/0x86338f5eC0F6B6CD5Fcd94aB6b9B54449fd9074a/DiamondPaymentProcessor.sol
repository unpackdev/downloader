// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";

contract DiamondPaymentProcessor is Initializable, AccessControlUpgradeable {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  IERC20Upgradeable public paymentToken;
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
      __AccessControl_init();
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(OPERATOR_ROLE, msg.sender);
  }

  function setContracts(
    IERC20Upgradeable _paymentToken
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paymentToken = _paymentToken;
  }

  function getTransferable(address[] calldata _addresses, uint256 _minBalance) public view returns (address[] memory entries) {
    uint256[] memory index = new uint256[](_addresses.length);
    uint256 indexLength = 0;
    for (uint i = 0; i < _addresses.length; i++) {
      if (paymentToken.allowance(_addresses[i], address(this)) < _minBalance) continue;
      if (paymentToken.balanceOf(_addresses[i]) < _minBalance) continue;
      index[indexLength++] = i;
    }

    entries = new address[](indexLength);
    for (uint256 i = 0; i < indexLength; i++) {
      entries[i] = _addresses[index[i]];
    }
    return entries;
  }

  function claimMany(address[] calldata _addresses, uint256 _amount, address dest) external onlyRole(OPERATOR_ROLE) {
    for (uint i = 0; i < _addresses.length; i++) {
      paymentToken.transferFrom(_addresses[i], dest, _amount);
    }
  }

  function claimManyToMany(address[] calldata _addresses, uint256[] calldata _amounts, address[] calldata dests) external onlyRole(OPERATOR_ROLE) {
    for (uint i = 0; i < _addresses.length; i++) {
      paymentToken.transferFrom(_addresses[i], dests[i], _amounts[i]);
    }
  }

  /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
  uint256[42] private __gap;
}