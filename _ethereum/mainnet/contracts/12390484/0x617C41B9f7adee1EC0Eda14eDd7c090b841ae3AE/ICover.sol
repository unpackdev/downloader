// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ICoverERC20.sol";

/**
 * @title Cover interface
 * @author crypto-pumpkin
 */
interface ICover {
  event CovTokenCreated(address);
  event CoverDeployCompleted();
  event Redeemed(string _type, address indexed _account, uint256 _amount);
  event FutureTokenConverted(address indexed _futureToken, address indexed claimCovToken, uint256 _amount);

  // state vars
  function BASE_SCALE() external view returns (uint256);
  function deployComplete() external view returns (bool);
  function expiry() external view returns (uint48);
  function collateral() external view returns (address);
  function noclaimCovToken() external view returns (ICoverERC20);
  function name() external view returns (string memory);
  function feeRate() external view returns (uint256);
  function totalCoverage() external view returns (uint256);
  function mintRatio() external view returns (uint256);
  /// @notice created as initialization, cannot be changed
  function claimNonce() external view returns (uint256);
  function futureCovTokens(uint256 _index) external view returns (ICoverERC20);
  function claimCovTokenMap(bytes32 _risk) external view returns (ICoverERC20);
  function futureCovTokenMap(ICoverERC20 _futureCovToken) external view returns (ICoverERC20 _claimCovToken);

  // extra view
  function viewRedeemable(address _account, uint256 _coverageAmt) external view returns (uint256);
  function getCovTokens() external view
    returns (
      ICoverERC20 _noclaimCovToken,
      ICoverERC20[] memory _claimCovTokens,
      ICoverERC20[] memory _futureCovTokens);

  // user action
  function deploy() external;
  /// @notice convert futureTokens to claimTokens
  function convert(ICoverERC20[] calldata _futureTokens) external;
  /// @notice redeem func when there is a claim on the cover, aka. the cover is affected
  function redeemClaim() external;
  /// @notice redeem func when the cover is not affected by any accepted claim, _amount is respected only when when no claim accepted before expiry (for cover with expiry)
  function redeem(uint256 _amount) external;
  function collectFees() external;

  // access restriction - owner (CoverPool)
  function mint(uint256 _amount, address _receiver) external;
  function addRisk(bytes32 _risk) external;
}