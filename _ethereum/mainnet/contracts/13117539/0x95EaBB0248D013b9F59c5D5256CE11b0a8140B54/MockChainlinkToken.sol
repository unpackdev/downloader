// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./MintableErc20.sol";

/**
 * @title MockChainlinkToken
 * @author dYdX
 *
 * @notice Mock Chainlink token.
 */
contract MockChainlinkToken is
  MintableErc20
{
  address public _CALLED_WITH_TO_;
  uint256 public _CALLED_WITH_VALUE_;
  bytes public _CALLED_WITH_DATA_;

  constructor()
    MintableErc20('Mock Chainlink Token', 'LINK', 18)
  {}

  function transferAndCall(
    address to,
    uint256 value,
    bytes memory data
  )
    external
    returns (bool success)
  {
    _CALLED_WITH_TO_ = to;
    _CALLED_WITH_VALUE_ = value;
    _CALLED_WITH_DATA_ = data;
    return true;
  }
}
