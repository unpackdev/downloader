// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Math.sol";
import "./IAMPHClaimer.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IVaultController.sol";
import "./IVault.sol";

/// @notice AMPHClaimer contract, used to exchange CVX and CRV at a fixed rate for AMPH
contract AMPHClaimer is IAMPHClaimer, Ownable {
  using SafeERC20 for IERC20;

  uint256 internal constant _BASE = 1 ether;

  /// @dev Constant used in the formula
  uint256 internal constant _FIFTY_MILLIONS = 50_000_000_000_000; // 50_000_000 * 1e6;

  /// @dev Constant used in the formula
  uint256 internal constant _TWENTY_FIVE_THOUSANDS = 25_000_000_000; // 25_000 * 1e6;

  /// @dev Constant used in the formula
  uint256 internal constant _FIFTY = 50_000_000; // 50 * 1e6;

  /// @dev The base supply of AMPH per cliff, denominated in 1e6
  uint256 public constant BASE_SUPPLY_PER_CLIFF = 8_000_000_000_000; // 8_000_000 * 1e6;

  /// @dev The total number of cliffs (for both tokens)
  uint256 public constant TOTAL_CLIFFS = 1000;

  /// @dev The CVX token
  IERC20 public immutable CVX;

  /// @dev The CRV token
  IERC20 public immutable CRV;

  /// @dev The AMPH token
  IERC20 public immutable AMPH;

  /// @dev The total amount of AMPH minted for rewards in CRV, denominated in 1e6
  uint256 public distributedAmph;

  /// @dev Percentage of rewards taken in CVX (1e18 == 100%)
  uint256 public cvxRewardFee;

  /// @dev Percentage of rewards taken in CRV (1e18 == 100%)
  uint256 public crvRewardFee;

  /// @dev The vault controller
  IVaultController public vaultController;

  constructor(
    address _vaultController,
    IERC20 _amph,
    IERC20 _cvx,
    IERC20 _crv,
    uint256 _cvxRewardFee,
    uint256 _crvRewardFee
  ) {
    vaultController = IVaultController(_vaultController);
    CVX = _cvx;
    CRV = _crv;
    AMPH = _amph;

    cvxRewardFee = _cvxRewardFee;
    crvRewardFee = _crvRewardFee;
  }

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
  ) external override returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimedAmph) {
    (_cvxAmountToSend, _crvAmountToSend, _claimedAmph) =
      _claimable(msg.sender, _vaultId, _cvxTotalRewards, _crvTotalRewards);

    /// Update the state
    if (_crvAmountToSend != 0 && _claimedAmph != 0) distributedAmph += (_claimedAmph / 1e12); // scale back to 1e6

    CVX.safeTransferFrom(msg.sender, owner(), _cvxAmountToSend);
    CRV.safeTransferFrom(msg.sender, owner(), _crvAmountToSend);

    // transfer AMPH token to minter
    AMPH.safeTransfer(_beneficiary, _claimedAmph);

    emit ClaimedAmph(msg.sender, _cvxAmountToSend, _crvAmountToSend, _claimedAmph);
  }

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
  ) external view override returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimableAmph) {
    (_cvxAmountToSend, _crvAmountToSend, _claimableAmph) =
      _claimable(_sender, _vaultId, _cvxTotalRewards, _crvTotalRewards);
  }

  /// @notice Used by governance to change the vault controller
  /// @param _newVaultController The new vault controller
  function changeVaultController(address _newVaultController) external override onlyOwner {
    vaultController = IVaultController(_newVaultController);

    emit ChangedVaultController(_newVaultController);
  }

  /// @notice Used by governance to recover tokens from the contract
  /// @param _token The token to recover
  /// @param _amount The amount to recover
  function recoverDust(address _token, uint256 _amount) external override onlyOwner {
    IERC20(_token).safeTransfer(owner(), _amount);

    emit RecoveredDust(_token, owner(), _amount);
  }

  /// @notice Used by governance to change the fee taken from the CVX reward
  /// @param _newFee The new reward fee
  function changeCvxRewardFee(uint256 _newFee) external override onlyOwner {
    cvxRewardFee = _newFee;

    emit ChangedCvxRewardFee(_newFee);
  }

  /// @notice Used by governance to change the fee taken from the CRV reward
  /// @param _newFee The new reward fee
  function changeCrvRewardFee(uint256 _newFee) external override onlyOwner {
    crvRewardFee = _newFee;

    emit ChangedCrvRewardFee(_newFee);
  }

  /// @dev Receives a total and a percentage, returns the amount equivalent of the percentage
  function _totalToFraction(uint256 _total, uint256 _fraction) internal pure returns (uint256 _amount) {
    if (_total == 0) return 0;
    _amount = (_total * _fraction) / _BASE;
  }

  /// @dev Doesn't revert but returns 0 so the vault contract doesn't revert on calling the claim function
  /// @dev Returns the claimable amount of AMPH, also the CVX and CRV the contract will take from the user
  function _claimable(
    address _sender,
    uint96 _vaultId,
    uint256 _cvxTotalRewards,
    uint256 _crvTotalRewards
  ) internal view returns (uint256 _cvxAmountToSend, uint256 _crvAmountToSend, uint256 _claimableAmph) {
    if (_sender != vaultController.vaultIdVaultAddress(_vaultId)) return (0, 0, 0);

    uint256 _amphBalance = AMPH.balanceOf(address(this));

    // if amounts are zero, or AMPH balance is zero simply return all zeros
    if (_crvTotalRewards == 0 || _amphBalance == 0) return (0, 0, 0);

    uint256 _cvxRewardsFeeToExchange = _totalToFraction(_cvxTotalRewards, cvxRewardFee);
    uint256 _crvRewardsFeeToExchange = _totalToFraction(_crvTotalRewards, crvRewardFee);

    uint256 _amphByCrv = _calculate(_crvRewardsFeeToExchange);

    // Check if all cliffs consumed
    if (_getCliff((_amphByCrv / 1e12) + distributedAmph) >= TOTAL_CLIFFS) return (0, 0, 0);

    // check for rounding errors
    if (_amphByCrv == 0) return (0, 0, 0);

    if (_amphBalance >= _amphByCrv) {
      // contract has the full amount
      _cvxAmountToSend = _cvxRewardsFeeToExchange;
      _crvAmountToSend = _crvRewardsFeeToExchange;
      _claimableAmph = _amphByCrv;
    } else {
      // contract doesnt have the full amount
      return (0, 0, 0);
    }
  }

  /// @dev Returns the rate of the token, denominated in 1e6
  function _getRate(uint256 _distributedAmph) internal pure returns (uint256 _rate) {
    uint256 _foo = (_TWENTY_FIVE_THOUSANDS * BASE_SUPPLY_PER_CLIFF) / Math.max(_distributedAmph, _FIFTY_MILLIONS);
    uint256 _bar = (_distributedAmph * 1e12) / (BASE_SUPPLY_PER_CLIFF * _FIFTY);

    _rate = 1e6 + (_foo - _bar);
  }

  /// @dev Returns how much AMPH would be minted given a token amount
  function _calculate(uint256 _tokenAmountToSend) internal view returns (uint256 _amphAmount) {
    if (_tokenAmountToSend == 0) return 0;

    uint256 _tempAmountReceived = _tokenAmountToSend; // CRV, 1e18
    uint256 _amphToMint; // 1e18

    uint256 _distributedAmph = distributedAmph;

    while (_tempAmountReceived > 0) {
      uint256 _amphForThisTurn;

      // all cliffs start when a certain amount of CRV is accumulated and finish when a certain amount is reached, this is the start of the current cliff
      uint256 _bottomLastCliff = _getCliff(_distributedAmph) * BASE_SUPPLY_PER_CLIFF;

      // get rate
      uint256 _rate = _getRate(_distributedAmph); // 1e6

      // calculate how many AMPH to mint given that rate.
      // transform the CRV amount to 1e6 and multiply.
      // perform the mul first to avoid rounding errors.
      _amphForThisTurn = ((_rate * _tempAmountReceived) / 1e12) / 1e6; // 1e6

      // calculate the amph available for this cliff
      uint256 _amphAvailableForThisCliff = (_bottomLastCliff + BASE_SUPPLY_PER_CLIFF) - _distributedAmph; // 1e6

      // check if the amount of amph to mint surpasses the cliff
      if (_amphAvailableForThisCliff < _amphForThisTurn) {
        /// surpassing the cliff
        _amphForThisTurn = _amphAvailableForThisCliff;
        // calculate how many CRV are entering this cliff
        uint256 _amountTokenToEnter = (_amphAvailableForThisCliff * 1e18) / _rate;
        _tempAmountReceived -= _amountTokenToEnter;
      } else {
        /// within the cliff
        _tempAmountReceived = 0;
      }

      _distributedAmph += _amphForThisTurn; // 1e6

      _amphToMint += (_amphForThisTurn * 1e12); // 1e18
    }

    // return
    _amphAmount = _amphToMint;
  }

  /// @dev Returns the current cliff, it will round down but is on purpose
  function _getCliff(uint256 _distributedAmph) internal pure returns (uint256 _cliff) {
    _cliff = _distributedAmph / BASE_SUPPLY_PER_CLIFF;
  }
}
