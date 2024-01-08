pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";
import "./CToken.sol";
import "./EIP20Interface.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./SafeMath.sol";

/**
 * @notice Stores mapping of a token address to a Chainlink aggregator that reports the price
 * @dev Each aggregator must return Token/USD price and conform to AggregatorV3Interface
 */
contract ChainlinkReporter is PriceOracle, OracleErrorReporter {
  using SafeMath for uint256;

  /// @notice Administrator for this contract
  address public admin;

  /// @notice Pending administrator for this contract
  address public pendingAdmin;

  /// @notice Fallback oracle to query when a stale price is received from Chainlink
  address public fallbackOracle;

  /// @notice If an oracle price is odler than this many seconds, it's considered stale and not used
  uint256 public staleThreshold;

  /// @dev A pair of token-aggregator contract addresses
  struct OracleMap {
    address token; // underlying ERC20 token address (not a cToken address)
    address aggregator; // Chainlink aggregator contract, or other oracle contract confirming to AggregatorV3Interface
  }

  /// @notice Stores the list of ERC-20 tokens mapped to their aggregator contracts
  mapping(address => address) public aggregators;

  /// @notice Placeholder address to represent ETH
  address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice Emitted when the oracle addresses are configured
  event AddedOrUpdatedTokenOracle(address token, address aggregator);

  /// @notice Emitted when the staleThreshold is updated
  event StaleThresholdSet(uint256 oldThreshold, uint256 newThreshold);

  /// @notice Emitted when the fallbackOracle is updated
  event FallbackOracleSet(address oldFallback, address newFallback);

  /// @notice Event emitted when pendingAdmin is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /// @notice Event emitted when pendingAdmin is accepted, which means admin is updated
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @param _oracles Array of token-aggregator pairs to initialize state with
   * @param _staleThreshold If an oracle price is odler than this many seconds, it's considered stale and not used
   */
  constructor(OracleMap[] memory _oracles, uint256 _staleThreshold) public {
    admin = msg.sender;
    staleThreshold = _staleThreshold;
    addOrUpdateTokenOraclesInternal(_oracles);
  }

  // ==================================== Primary functionality ====================================

  /**
   * @notice Adds or updates configured token-aggregator pairs
   * @dev Aggregator must return the token's price in USD
   * @param _oracles Array of token-aggregator pairs to add or update
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function addOrUpdateTokenOracles(OracleMap[] calldata _oracles) external returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ADD_OR_UPDATE_ORACLES_OWNER_CHECK);
    }

    // Execute the changes
    addOrUpdateTokenOraclesInternal(_oracles);
    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Updates the threshold for determining stale prices
   * @param _staleThreshold If an oracle price is odler than this many seconds, it's considered stale and not used
   */
  function setStaleThreshold(uint256 _staleThreshold) external returns (uint256) {
    require(msg.sender == admin, "Only admin can update staleThreshold");
    emit StaleThresholdSet(staleThreshold, _staleThreshold);
    staleThreshold = _staleThreshold;
  }

  /**
   * @notice Sets the fallback oracle
   * @param _fallbackOracle Address of the new fallback oracle to use
   */
  function setFallbackOracle(address _fallbackOracle) external returns (uint256) {
    require(msg.sender == admin, "Only admin can update fallbackOracle");
    emit FallbackOracleSet(fallbackOracle, _fallbackOracle);
    fallbackOracle = _fallbackOracle;
  }

  /**
   * @notice Adds or updates configured token-aggregator pairs
   * @dev Aggregator must return the token's price in USD
   * @dev Use an aggregator address of zero to remove an oracle
   * @param _oracles Array of token-aggregator pairs to add or update
   */
  function addOrUpdateTokenOraclesInternal(OracleMap[] memory _oracles) internal {
    for (uint8 _index = 0; _index < _oracles.length; _index++) {
      // Parse input parameters
      address _aggregator = _oracles[_index].aggregator;
      address _token = _oracles[_index].token;

      // Use the zero address to remove an oracle. If not the zero address, validate it returns a price
      if (_aggregator != address(0)) {
        (, int256 _tokenPrice, , , ) = AggregatorV3Interface(_aggregator).latestRoundData();
        require(_tokenPrice > 0, "Oracle does not return a valid price"); // all expected prices will be positive values
      }

      // Set the oracle
      aggregators[_token] = _aggregator;
      emit AddedOrUpdatedTokenOracle(_token, _aggregator);
    }
  }

  /**
   * @notice Fetches the latest USD price of a given token
   * @dev Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
   * @param _cToken The tcToken address for which a USD price is needed; must be configured in `aggregators`
   * @return USD price of the cToken's underlying, scaled appropriately for the Comptroller
   */
  function getUnderlyingPrice(CToken _cToken) external view returns (uint256) {
    address underlying = _cToken.underlying();
    require(hasOracle(underlying), "Token has no oracle set");
    AggregatorV3Interface _aggregator = AggregatorV3Interface(aggregators[underlying]);

    /* Interface for latestRoundData return:
      (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      );
    */
    (, int256 _tokenPrice, , uint256 _updatedAt, ) = _aggregator.latestRoundData();

    // Verify that data is not stale
    if (_updatedAt < block.timestamp.sub(staleThreshold)) {
      // If stale and we have no fallback oracle, revert
      if (fallbackOracle == address(0)) revert("Price is stale");

      // If stale and we do have fallback oracle, use it
      return PriceOracle(fallbackOracle).getUnderlyingPrice(_cToken);
    }

    // Convert aggregator price to format needed by the Comptroller
    return priceToComptrollerFormat(uint256(_tokenPrice), underlying, address(_aggregator));
  }

  /**
   * @notice Helper method to verify if a token has an oracle aggregator contract defined
   * @param _token Token to check
   * @return True if an oracle aggregator contract is defined for the specified token
   */
  function hasOracle(address _token) public view returns (bool) {
    return aggregators[_token] != address(0);
  }

  // ===================================== Conversion helpers ======================================

  /**
   * @notice Get token decimals, accounting for ETH
   * @dev This function works for any ERC20 token or Chainlink aggregator contracts, because the
   * Aggregator interface also defines a `decimals` function
   * @return Number of decimals the token has
   */
  function getTokenDecimals(address _address) internal view returns (uint8) {
    return _address == ETH_ADDRESS ? 18 : EIP20Interface(_address).decimals();
  }

  /**
   * @notice Convert token price from aggregator to Comptroller format, based on number of decimals aggregator and
   * token have
   * @dev Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit).
   * Aggregators are scaled by X decimals, and tokens by Y, so we scale prices by 1e(36 - X - Y).
   * Compound's own implementation of this can be found here: https://github.com/compound-finance/open-oracle/blob/046b32bbf239fda2f829d231e5850f4808133b3f/contracts/Uniswap/UniswapAnchoredView.sol#L129-L140
   * @param _price Price of the token, in units returned by the aggregator contract
   * @param _underlying Address of the underlying token
   * @param _aggregator Address of the aggregator
   * @return USD price scaled appropriately for the Comptroller
   */
  function priceToComptrollerFormat(
    uint256 _price,
    address _underlying,
    address _aggregator
  ) internal view returns (uint256) {
    // Get number of decimals used by the aggregator and the underlying token
    uint8 aggregatorDecimals = getTokenDecimals(_aggregator);
    uint8 tokenDecimals = getTokenDecimals(_underlying);
    // Adjust for number of decimals returned by aggregator and underlying token
    return _price.mul(10**(uint256(36).sub(aggregatorDecimals).sub(tokenDecimals)));
  }

  // ====================================== Admin management =======================================
  // These methods are the same as the versions implemented in CToken.sol and Unitroller.sol

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address newPendingAdmin) external returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
    }

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(Error.NO_ERROR);
  }
}
