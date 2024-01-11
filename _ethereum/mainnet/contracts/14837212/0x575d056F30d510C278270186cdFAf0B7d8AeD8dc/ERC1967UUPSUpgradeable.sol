// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Context.sol";
import "./Address.sol";
import "./IERC1967Proxy.sol";

abstract contract ERC1967UUPSUpgradeable is Context, IERC1967Proxy {
  using Address for address;

  address internal immutable _thisCopy;

  uint256 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
  uint256 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  uint256 private constant _NO_ROLLBACK = 2;
  uint256 private constant _ROLLBACK_IN_PROGRESS = 3;

  constructor() {
    _thisCopy = address(this);
    assert(_IMPLEMENTATION_SLOT == uint256(keccak256("eip1967.proxy.implementation")) - 1);
    assert(_ROLLBACK_SLOT == uint256(keccak256("eip1967.proxy.rollback")) - 1);
  }

  function implementation() public view virtual override returns (address result) {
    assembly ("memory-safe") {
      result := sload(_IMPLEMENTATION_SLOT)
    }
  }

  function _setImplementation(address newImplementation) private {
    assembly ("memory-safe") {
      sstore(_IMPLEMENTATION_SLOT, newImplementation)
    }
  }

  function _isRollback() internal view returns (bool) {
    uint256 slotValue;
    assembly ("memory-safe") {
      slotValue := sload(_ROLLBACK_SLOT)
    }
    return slotValue == _ROLLBACK_IN_PROGRESS;
  }

  function _setRollback(bool rollback) private {
    uint256 slotValue = rollback ? _ROLLBACK_IN_PROGRESS : _NO_ROLLBACK;
    assembly ("memory-safe") {
      sstore(_ROLLBACK_SLOT, slotValue)
    }
  }

  function _requireProxy() internal view {
    require(implementation() == _thisCopy && address(this) != _thisCopy, "ERC1967UUPSUpgradeable: only proxy");
  }

  modifier onlyProxy() {
    _requireProxy();
    _;
  }

  function initialize() public virtual onlyProxy {
    _setRollback(false);
  }

  function _encodeDelegateCall(bytes memory callData) internal view virtual returns (bytes memory) {
    return callData;
  }

  function _checkImplementation(address newImplementation, bool rollback) internal virtual {
    require(implementation() == newImplementation, "ERC1967UUPSUpgradeable: interfered with implementation");
    require(rollback || !_isRollback(), "ERC1967UUPSUpgradeable: interfered with rollback");
  }

  function _checkRollback(bool rollback) private {
    if (!rollback) {
      _setRollback(true);
      address newImplementation = implementation();
      newImplementation.functionDelegateCall(
        _encodeDelegateCall(abi.encodeCall(this.upgrade, (_thisCopy))),
        "ERC1967UUPSUpgradeable: rollback upgrade failed"
      );
      _setRollback(false);
      require(implementation() == _thisCopy, "ERC1967UUPSUpgradeable: upgrade breaks further upgrades");
      emit Upgraded(newImplementation);
      _setImplementation(newImplementation);
    }
  }

  function upgrade(address newImplementation) public payable virtual override onlyProxy {
    bool rollback = _isRollback();
    _setImplementation(newImplementation);
    _checkImplementation(newImplementation, rollback);
    _checkRollback(rollback);
  }

  function upgradeAndCall(address newImplementation, bytes calldata data) public payable virtual override onlyProxy {
    bool rollback = _isRollback();
    _setImplementation(newImplementation);
    newImplementation.functionDelegateCall(
      _encodeDelegateCall(data),
      "ERC1967UUPSUpgradeable: initialization failed"
    );
    _checkImplementation(newImplementation, rollback);
    _checkRollback(rollback);
  }
}
