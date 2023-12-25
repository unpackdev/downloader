// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC2612.sol";
import "./INativeMetaTransaction.sol";
import "./SafePermit.sol";
import "./Revert.sol";

contract PermitAndCall {
  using SafePermit for IERC2612;
  using SafePermit for IERC20PermitAllowed;
  using SafePermit for IERC20MetaTransaction;
  using Revert for bytes;

  address payable public constant target =
    payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

  function permitAndCall(
    IERC2612 token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(domainSeparatorSelector, owner, target, amount, deadline, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20PermitAllowed token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 nonce,
    uint256 deadline,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(
      domainSeparatorSelector, owner, target, nonce, deadline, allowed, v, r, s
    );
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20MetaTransaction token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(domainSeparatorSelector, owner, target, amount, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }
}
