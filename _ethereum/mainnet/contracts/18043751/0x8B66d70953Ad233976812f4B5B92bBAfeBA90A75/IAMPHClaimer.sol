// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IVaultController.sol";

/// @title AMPHClaimer Interface
interface IAMPHClaimer {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

  // @notice Emited when a vault claims AMPH
  // @param _vaultClaimer The address of the vault that claimed
  // @param _cvxTotalRewards The amount of CVX sent in exchange of AMPH
  // @param _crvTotalRewards The amount of CRV sent in exchange of AMPH
  // @param _amphAmount The amount of AMPH received

  event ClaimedAmph(
    address indexed _vaultClaimer, uint256 _cvxTotalRewards, uint256 _crvTotalRewards, uint256 _amphAmount
  );

  // @notice Emited when governance changes the vault controller
  // @param _newVaultController The address of the new vault controller

  event ChangedVaultController(address indexed _newVaultController);

  // @notice Emited when governance recovers a token from the contract
  // @param _token the token recovered
  // @param _receiver the receiver of the tokens
  // @param _amount the amount recovered

  event RecoveredDust(address indexed _token, address _receiver, uint256 _amount);

  // @notice Emited when governance changes the CVX reward fee
  // @param _newCvxReward the new fee

  event ChangedCvxRewardFee(uint256 _newCvxReward);

  // @notice Emited when governance changes the CRV reward fee
  // @param _newCrvReward the new fee

  event ChangedCrvRewardFee(uint256 _newCrvReward);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice The address of the CVX token
  function CVX() external view returns (IERC20 _cvx);

  /// @notice The address of the CRV token
  function CRV() external view returns (IERC20 _crv);

  /// @notice The address of the AMPH token
  function AMPH() external view returns (IERC20 _amph);

  /// @notice The base supply of AMPH per cliff, denominated in 1e6
  function BASE_SUPPLY_PER_CLIFF() external view returns (uint256 _baseSupplyPerCliff);

  /// @notice The total amount of AMPH minted for rewards in CRV, denominated in 1e6
  function distributedAmph() external view returns (uint256 _distributedAmph);

  /// @notice The total number of cliffs (for both tokens)
  function TOTAL_CLIFFS() external view returns (uint256 _totalCliffs);

  /// @notice Percentage of rewards taken in CVX (1e18 == 100%)
  function cvxRewardFee() external view returns (uint256 _cvxRewardFee);

  /// @notice Percentage of rewards taken in CRV (1e18 == 100%)
  function crvRewardFee() external view returns (uint256 _crvRewardFee);

  /// @notice The vault controller
  function vaultController() external view returns (IVaultController _vaultController);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Claims an amount of AMPH given a CVX and CRV quantity
  /// @param _vaultId The vault id that is claiming
  /// @param _cvxTotalRewards The max CVX amount to exchange from the sender
  /// @param _crvTotalRewards The max CVR amount to exchange from the sender
  /// @param _beneficiary The receiver of the AMPH rewards
  /// @return _cvxAmountToSend The amount of CVX that the treasury got
  /// @return _crvAmountToSend The amount of CRV that the treasury got
  /// @return _claimedAmph The amount of AMPH received by the beneficiary
  function claimAmph(
    uint96 _vaultId,
    uint256 _cvxTotalRewards,
    uint256 _crvTotalRewards,
    address _beneficiary
  ) external returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimedAmph);

  /// @notice Returns the claimable amount of AMPH given a CVX and CRV quantity
  /// @param _sender The address of the account claiming
  /// @param _vaultId The vault id that is claiming
  /// @param _cvxTotalRewards The max CVX amount to exchange from the sender
  /// @param _crvTotalRewards The max CVR amount to exchange from the sender
  /// @return _cvxAmountToSend The amount of CVX the user will have to send
  /// @return _crvAmountToSend The amount of CRV the user will have to send
  /// @return _claimableAmph The amount of AMPH that would be received by the beneficiary
  function claimable(
    address _sender,
    uint96 _vaultId,
    uint256 _cvxTotalRewards,
    uint256 _crvTotalRewards
  ) external view returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimableAmph);

  /// @notice Used by governance to change the vault controller
  /// @param _newVaultController The new vault controller
  function changeVaultController(address _newVaultController) external;

  /// @notice Used by governance to recover tokens from the contract
  /// @param _token The token to recover
  /// @param _amount The amount to recover
  function recoverDust(address _token, uint256 _amount) external;

  /// @notice Used by governance to change the fee taken from the CVX reward
  /// @param _newFee The new reward fee
  function changeCvxRewardFee(uint256 _newFee) external;

  /// @notice Used by governance to change the fee taken from the CRV reward
  /// @param _newFee The new reward fee
  function changeCrvRewardFee(uint256 _newFee) external;
}
