// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";

/** @notice Interface with USDC's permit method. From
 *          https://github.com/centrehq/centre-tokens/blob/master/contracts/v2/FiatTokenV2.sol
 */
interface IUSDC is IERC20 {
  function permit(
      address owner,
      address spender,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
  ) external;
}
