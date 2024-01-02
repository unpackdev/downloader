// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IPool.sol";

interface IBaseTokenWrapper {
  struct PermitSignature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice Converts amount of token to wrapped version and supplies to Pool
   * @param amount The amount of the token to wrap and supply to the Pool
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards
   * @return The final amount supplied to the Pool, post-wrapping
   */
  function supplyToken(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external returns (uint256);

  /**
   * @notice Converts amount of token to wrapped version and supplies to Pool, using permit for allowance
   * @param amount The amount of the token to wrap and supply to the Pool
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards
   * @param signature The EIP-712 signature data used for permit
   * @return The final amount supplied to the Pool, post-wrapping
   */
  function supplyTokenWithPermit(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    PermitSignature calldata signature
  ) external returns (uint256);

  /**
   * @notice Withdraws the wrapped token from the Pool and unwraps it, sending to the recipient
   * @param amount The amount of the token to withdraw from the Pool and unwrap
   * @param to The address that will receive the unwrapped token
   * @return The final amount withdrawn from the Pool, post-unwrapping
   */
  function withdrawToken(uint256 amount, address to) external returns (uint256);

  /**
   * @notice Withdraws the wrapped token from the Pool and unwraps it, sending to the recipient, using permit for allowance
   * @param amount The amount of the token to withdraw from the Pool and unwrap
   * @param to The address that will receive the unwrapped token
   * @param signature The EIP-712 signature data used for permit
   * @return The final amount withdrawn from the Pool, post-unwrapping
   */
  function withdrawTokenWithPermit(
    uint256 amount,
    address to,
    PermitSignature calldata signature
  ) external returns (uint256);

  /**
   * @notice Provides way for the contract owner to rescue ERC-20 tokens
   * @param token The address of the token to withdraw from this contract
   * @param to The address of the recipient of rescued funds
   * @param amount The amount of token rescued
   */
  function rescueTokens(IERC20 token, address to, uint256 amount) external;

  /**
   * @notice Provides way for the contract owner to rescue ETH
   * @param to The address of the recipient of rescued funds
   * @param amount The amount of ETH rescued
   */
  function rescueETH(address to, uint256 amount) external;

  /**
   * @notice Computes the amount of tokenOut received for a provided amount of tokenIn
   * @param amount The amount of tokenIn
   * @return The amount of tokenOut
   */
  function getTokenOutForTokenIn(
    uint256 amount
  ) external view returns (uint256);

  /**
   * @notice Computes the amount of tokenIn received for a provided amount of tokenOut
   * @param amount The amount of tokenOut
   * @return The amount of tokenIn
   */
  function getTokenInForTokenOut(
    uint256 amount
  ) external view returns (uint256);

  /**
   * @notice Returns the address of the ERC-20 token that will be wrapped in supply operations
   * @return The address of tokenIn
   */
  function TOKEN_IN() external view returns (address);

  /**
   * @notice Returns the address of the ERC-20 token received upon wrapping
   * @return The address of tokenOut
   */
  function TOKEN_OUT() external view returns (address);

  /**
   * @notice Returns the address of the Aave Pool
   * @return The address of the Aave Pool contract
   */
  function POOL() external view returns (IPool);
}
