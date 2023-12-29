pragma solidity 0.8.21;

abstract contract Revert {
  /**
   * @dev For more efficient reverts.
   */
  function _revert(bytes4 errorSelector) internal pure {
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }
}
