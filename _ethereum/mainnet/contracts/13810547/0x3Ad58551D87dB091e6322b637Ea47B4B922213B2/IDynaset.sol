// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IDynaset {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index of address in tokens array
   * @param balance token balance
   */
  struct Record {
      bool bound;   // is token bound to dynaset
      bool ready;
      uint index;   // private
      uint96 denorm;  // denormalized weight
      uint256 balance;
  }

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

  event LOG_TOKEN_READY(address indexed token);

  event LOG_PUBLIC_SWAP_TOGGLED(bool enabled);

  function configure(
    address controller,
    address dam,
    string calldata name,
    string calldata symbol
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider
  ) external;
  

  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata Denorms
  ) external;

  function joinDynaset(uint256 _amount) external;

  function exitDynaset(uint256 _amount) external;

  //function updateAfterSwap(address token) external;

  function getController() external view returns (address);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens() external view returns (address[] memory tokens);

  function getDenormalizedWeight(address token) external view returns (uint256/* denorm */);

  function getTokenRecord(address token) external view returns (Record memory record);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

}