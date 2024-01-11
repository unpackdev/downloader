// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IRestrictedIndexPool is IERC20 {
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function initialize(address _lpBurn, address _pair) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external;

  function exitPoolTo(address to, uint256 poolAmountIn) external;

  function redeemAll() external;

  function isPublicSwap() external view returns (bool);

  function getSwapFee()
    external
    view
    returns (
      uint256 /* swapFee */
    );

  function getExitFee()
    external
    view
    returns (
      uint256 /* exitFee */
    );

  function getController() external view returns (address);

  function getExitFeeRecipient() external view returns (address);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens()
    external
    view
    returns (address[] memory tokens);

  function getDenormalizedWeight(address token)
    external
    view
    returns (
      uint256 /* denorm */
    );

  function getTokenRecord(address token)
    external
    view
    returns (Record memory record);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);
}
