// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

import "./ManagedPool.sol";

/**
 * @title SponsorPool
 */
contract SponsorPool is ERC20, ERC20Permit, ManagedPool {
  using SafeERC20 for IERC20;

  constructor(ERC20 _token)
    ERC20(
      _concat("SponsorPool: ", _token.name()),
      _concat("f", _token.symbol())
    )
    ERC20Permit(_concat("SponsorPool: ", _token.name()))
  {
    stakedToken = IERC20(_token);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER, msg.sender);

    stakedToken.safeApprove(msg.sender, 2**256 - 1);
    emit Created(address(this), stakedToken);
  }

  function _concat(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(bytes.concat(bytes(a), bytes(b)));
  }
}
