// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

/// Partial DividendPayingToken (only functions called in SpaceApe contract)
interface IDividendPayingToken {
  function distributeTokenRewardDividends(uint256 amount) external;
}

/// Partial TokenDividendTracker (only functions called in SpaceApe contract)
interface ITokenDividendTracker is IERC20, IDividendPayingToken {
  function excludeFromDividends(address account) external;
  function includeInDividends(address account) external;
  function isexcludeFromDividends(address account) external view returns (bool);
  function setBalance(address payable account, uint256 newBalance) external;
  function process(uint256 gas) external returns (uint256, uint256, uint256);
}

// /// Ownable (only functions called in SpaceApe contract)
// interface IOwnable {
//   function owner() external view returns (address);
// }

// /// TokenDividendTracker from SpaceApe contract
// interface ITokenDividendTrackerFull is IERC20, IOwnable, IDividendPayingToken {
//   // uint256 public lastProcessedIndex;
//   // mapping(address => bool) public excludedFromDividends;
//   // mapping(address => uint256) public lastClaimTimes;
//   // uint256 public claimWait;
//   // uint256 public immutable minimumTokenBalanceForDividends;
//   event ExcludeFromDividends(address indexed account);
//   event IncludeInDividends(address indexed account);
//   event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
//   function withdrawDividend() external pure;
//   function excludeFromDividends(address account) external;
//   function includeInDividends(address account) external;
//   function isexcludeFromDividends(address account) external view returns (bool);
//   function updateClaimWait(uint256 newClaimWait) external;
//   function dividendTokenBalanceOf(address account) external view returns (uint256);
//   function getLastProcessedIndex() external view returns (uint256);
//   function getNumberOfTokenHolders() external view returns (uint256);
//   function getAccount(address _account) external view returns (
//     address account,
//     int256 index,
//     int256 iterationsUntilProcessed,
//     uint256 withdrawableDividends,
//     uint256 totalDividends,
//     uint256 lastClaimTime,
//     uint256 nextClaimTime,
//     uint256 secondsUntilAutoClaimAvailable
//   );
//   function getAccountAtIndex(uint256 index) external view returns (
//     address,
//     int256,
//     int256,
//     uint256,
//     uint256,
//     uint256,
//     uint256,
//     uint256
//   );
//   function setBalance(address payable account, uint256 newBalance) external;
//   function process(uint256 gas) external returns (uint256, uint256, uint256);
//   function processAccount(address payable account, bool automatic) external returns (bool);
// }
