pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ITrigger.sol";

interface IRariVault {
  function getFundBalance() external returns (uint256);

  function rariFundToken() external view returns (IERC20);
}

/**
 * @notice Defines a trigger that is toggled if the share price of the Rari vault drops by
 * over 50% between consecutive checks
 */
contract RariSharePrice is ITrigger {
  /// @notice Rari vault this trigger is for
  IRariVault public immutable market;

  /// @notice Token address of that vault
  IERC20 public immutable token;

  /// @notice Last read share price
  uint256 public lastPricePerShare;

  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev Tolerance for share price drop
  uint256 public constant tolerance = 500; // 500 / 1000 = 50% tolerance

  /**
   * @param _market Address of the Rari vault this trigger should protect
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _market
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set vault and save current share price
    market = IRariVault(_market);
    token = market.rariFundToken();
    lastPricePerShare = getPricePerShare();
  }

  /**
   * @dev Checks the Rari share price
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price
    uint256 _currentPricePerShare = getPricePerShare();

    // Check if current share price is below current share price, accounting for tolerance
    bool _status = _currentPricePerShare < ((lastPricePerShare * tolerance) / scale);

    // Save the new share price
    lastPricePerShare = _currentPricePerShare;

    // Return status
    return _status;
  }

  /**
   * @dev Returns the effective price per share of the vault
   */
  function getPricePerShare() internal returns (uint256) {
    // Both `getFundBalance() and `totalSupply()` return values with 18 decimals, so we scale the fund balance
    // before division to increase the precision of this division. Without this scaling, the division will floor
    // and often return 1, which is too coarse to be useful
    return (market.getFundBalance() * 1e18) / token.totalSupply();
  }
}
