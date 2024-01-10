// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

import "./ManagedPool.sol";
import "./Slashable.sol";

/**
 * @title StakingPool
 * @dev The DAOracle Network relies on decentralized risk pools. This is a
 * simple implementation of a staking pool which wraps a single arbitrary token
 * and provides a mechanism for recouping losses incurred by the deployer of
 * the staking pool. Pool ownership is represented as ERC20 tokens that can be
 * freely used as the holder sees fit. Holders of pool shares may make claims
 * proportional to their stake on the underlying token balance of the pool. Any
 * rewards or penalties applied to the pool will thus impact all holders.
 */
contract StakingPool is ERC20, ERC20Permit, ManagedPool, Slashable {
  using SafeERC20 for IERC20;

  constructor(
    ERC20 _token,
    uint256 _mintFee,
    uint256 _burnFee,
    address _feePayee
  )
    ERC20(
      _concat("StakingPool: ", _token.name()),
      _concat("dp", _token.symbol())
    )
    ERC20Permit(_concat("StakingPool: ", _token.name()))
  {
    stakedToken = IERC20(_token);
    mintFee = _mintFee;
    burnFee = _burnFee;
    feePayee = _feePayee;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER, msg.sender);
    _setupRole(SLASHER, msg.sender);

    stakedToken.safeApprove(msg.sender, 2**256 - 1);

    emit Created(address(this), stakedToken);
  }

  function underlying() public view override returns (IERC20) {
    return stakedToken;
  }

  function _concat(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(bytes.concat(bytes(a), bytes(b)));
  }
}
