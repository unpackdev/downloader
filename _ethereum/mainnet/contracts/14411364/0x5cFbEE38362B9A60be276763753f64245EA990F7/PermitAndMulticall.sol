// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./draft-IERC20Permit.sol";
import "./Address.sol";

/**
 * @notice Allows a user to permit token spend and then call multiple functions on a contract.
 */
contract PermitAndMulticall {
  /**
   * @notice Secp256k1 signature values.
   * @param deadline Timestamp at which the signature expires
   * @param v `v` portion of the signature
   * @param r `r` portion of the signature
   * @param s `s` portion of the signature
   */
  struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who want to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function _multicall(bytes[] calldata _data) internal virtual returns (bytes[] memory) {
    uint256 _dataLength = _data.length;
    bytes[] memory results = new bytes[](_dataLength);

    for (uint256 i; i < _dataLength; i++) {
      results[i] = Address.functionDelegateCall(address(this), _data[i]);
    }

    return results;
  }

  /**
   * @notice Allow a user to approve an ERC20 token and run various calls in one transaction.
   * @param _permitToken Address of the ERC20 token
   * @param _amount Amount of tickets to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function _permitAndMulticall(
    IERC20Permit _permitToken,
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) internal {
    _permitToken.permit(
      msg.sender,
      address(this),
      _amount,
      _permitSignature.deadline,
      _permitSignature.v,
      _permitSignature.r,
      _permitSignature.s
    );

    _multicall(_data);
  }
}
