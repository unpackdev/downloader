// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Initializable.sol";

contract VaultStorage is Initializable {

  bytes32 internal constant _BUNDLE_SLOT = 0xbfdef6be9e92dbc8169132dd5cf803a408d57bdfb3966c2cc0874fcc35ceacfd;
  bytes32 internal constant _UNDERLYING_SLOT = 0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
  bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;

  // constructor() public {
  //   assert(_BUNDLE_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.bundle")) - 1));
  //   assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
  //   assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
  // }

  function initializeVaultStorage(
    address _underlying,
    uint256 _underlyingUnit
  ) public initializer {

    assert(_BUNDLE_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.bundle")) - 1));
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
    assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
    _setUnderlying(_underlying);
    _setUnderlyingUnit(_underlyingUnit);
  }

  function _setBundle(address _address) internal {
    setAddress(_BUNDLE_SLOT, _address);
  }

  function _bundle() internal view returns (address) {
    return getAddress(_BUNDLE_SLOT);
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    setUint256(_UNDERLYING_UNIT_SLOT, _value);
  }

  function _underlyingUnit() internal view returns (uint256) {
    return getUint256(_UNDERLYING_UNIT_SLOT);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private big_empty_slot;
}
