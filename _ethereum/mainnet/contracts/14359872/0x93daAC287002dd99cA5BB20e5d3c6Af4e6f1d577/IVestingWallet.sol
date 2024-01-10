// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IDustCollector.sol";

/// @title VestingWallet contract
/// @notice Handles the vesting of ERC20 tokens for multiple beneficiaries
interface IVestingWallet is IDustCollector {
  // Errors

  /// @notice Throws when the length of the amounts do not match
  error WrongLengthAmounts();

  // Events

  /// @notice Emitted when a benefit is successfully added
  event BenefitAdded(address indexed token, address indexed beneficiary, uint256 amount, uint256 startDate, uint256 releaseDate);

  /// @notice Emitted when a benefit is successfully removed
  event BenefitRemoved(address indexed token, address indexed beneficiary, uint256 removedAmount);

  /// @notice Emitted when a benefit is successfully released
  event BenefitReleased(address indexed token, address indexed beneficiary, uint256 releasedAmount);

  // Structs

  /// @notice Stores benefit information by each beneficiary and token pair
  struct Benefit {
    uint256 amount; // Amount of vested token for the inputted beneficiary
    uint256 startDate; // Timestamp at which the benefit starts to take effect
    uint256 duration; // Seconds to unlock the full benefit
    uint256 released; // The amount of vested tokens already released
  }

  // Views

  /// @notice Lists users with an ongoing benefit
  /// @return _beneficiaries List of beneficiaries
  function getBeneficiaries() external view returns (address[] memory _beneficiaries);

  /// @notice Lists all the tokens that are currently vested
  /// @return _tokens List of vested tokens
  function getTokens() external view returns (address[] memory _tokens);

  /// @notice Lists the current vested tokens for the given address
  /// @param _beneficiary Address of the beneficiary
  /// @return _tokens List of vested tokens
  function getTokensOf(address _beneficiary) external view returns (address[] memory _tokens);

  /// @notice Returns the benefit data for a given token and beneficiary
  /// @param _token Address of ERC20 token to be vested
  /// @param _beneficiary Address of the beneficiary
  /// @return amount Amount of vested token for the inputted beneficiary
  /// @return startDate Timestamp at which the benefit starts to take effect
  /// @return duration Seconds to unlock the full benefit
  /// @return released The amount of vested tokens already released
  function benefits(address _token, address _beneficiary)
    external
    view
    returns (
      uint256 amount,
      uint256 startDate,
      uint256 duration,
      uint256 released
    );

  /// @notice Returns the end date of a vesting period
  /// @param _token Address of ERC20 vested token
  /// @param _beneficiary Address of the beneficiary
  /// @return _releaseDate The timestamp at which benefit will be fully released.
  function releaseDate(address _token, address _beneficiary) external view returns (uint256 _releaseDate);

  /// @notice Returns the claimable amount of a vested token for a specific beneficiary
  /// @dev If the vesting period did not end, it returns a proportional claimable amount
  /// @dev If the vesting period is over, it returns the complete vested amount
  /// @param _token Address of ERC20 token to be vested
  /// @param _beneficiary Address of the beneficiary
  /// @return _claimableAmount The amount of the vested token the beneficiary can claim at this point in time
  function releasableAmount(address _token, address _beneficiary) external view returns (uint256 _claimableAmount);

  /// @notice Returns the total amount of the given vested token across all beneficiaries
  /// @param _token Address of ERC20 token to be vested
  /// @return _totalAmount The total amount of requested tokens
  function totalAmountPerToken(address _token) external view returns (uint256 _totalAmount);

  // Methods

  /// @notice Creates a vest for a given beneficiary.
  /// @dev It will claim all previous benefits.
  /// @param _beneficiary Address of the beneficiary
  /// @param _startDate Timestamp at which the benefit starts to take effect
  /// @param _duration Seconds to unlock the full benefit
  /// @param _token Address of ERC20 token to be vested
  /// @param _amount Amount of vested token for the inputted beneficiary
  function addBenefit(
    address _beneficiary,
    uint256 _startDate,
    uint256 _duration,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Creates benefits for a group of beneficiaries
  /// @param _token Address of ERC20 token to be vested
  /// @param _beneficiaries Addresses of the beneficiaries
  /// @param _amounts Amounts of vested token for each beneficiary
  /// @param _startDate Timestamp at which the benefit starts to take effect
  /// @param _duration Seconds to unlock the full benefit
  function addBenefits(
    address _token,
    address[] memory _beneficiaries,
    uint256[] memory _amounts,
    uint256 _startDate,
    uint256 _duration
  ) external;

  /// @notice Removes a given benefit
  /// @notice Releases the claimable balance and transfers the pending benefit to governance
  /// @param _token Address of ERC20 token to be vested
  /// @param _beneficiary Address of the beneficiary
  function removeBenefit(address _token, address _beneficiary) external;

  /// @notice Removes all benefits from a given beneficiary
  /// @notice Releases the claimable balances and transfers the pending benefits to governance
  /// @param _beneficiary Address of the beneficiary
  function removeBeneficiary(address _beneficiary) external;

  /// @notice Releases a token in its correspondent amount to the function caller
  /// @param _token Address of ERC20 token to be vested
  function release(address _token) external;

  /// @notice Releases a token in its correspondent amount to a particular beneficiary
  /// @param _token Address of ERC20 token to be vested
  /// @param _beneficiary Address of the beneficiary
  function release(address _token, address _beneficiary) external;

  /// @notice Releases a list of tokens in their correspondent amounts to the function caller
  /// @param _tokens List of ERC20 token to be vested
  function release(address[] memory _tokens) external;

  /// @notice Releases a list of tokens in their correspondent amounts to a particular beneficiary
  /// @param _tokens List of ERC20 token to be vested
  /// @param _beneficiary Address of the beneficiary
  function release(address[] memory _tokens, address _beneficiary) external;

  /// @notice Releases all tokens in their correspondent amounts to the function caller
  function releaseAll() external;

  /// @notice Releases all tokens in their correspondent amounts to a particular beneficiary
  /// @param _beneficiary Address of the beneficiary
  function releaseAll(address _beneficiary) external;
}
