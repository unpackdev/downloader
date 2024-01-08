// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Lif2V2.sol";

/**
 * @dev Lif ERC20 token V3
 * This upgrade modifies token name from "LifToken" to "Lif"
 */
contract Lif2V3 is Lif2V2 {

  /**
   * @dev See {ERC20Upgradeable-name}.
   */
  function name()
    public
    view
    virtual
    override(ERC20Upgradeable)
    returns (string memory)
  {
    return "Lif";
  }

  /**
   * @dev See {EIP712Upgradeable-_EIP712NameHash}.
   */
  function _EIP712NameHash()
    internal
    virtual
    override(EIP712Upgradeable)
    view returns (bytes32)
  {
    return keccak256(bytes("Lif"));
  }
}
