pragma solidity 0.5.17;

import "./CErc20Immutable.sol";
import "./CEther.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./Strings.sol";
import "./TriggerInterface.sol";

/**
 * @notice Interface so ProtectionMarketFactory can use the same admin as the Comptroller
 */
interface ComptrollerAdmin {
  function admin() external view returns (address);
}

/**
 * @notice Factory contract for deploying protection markets
 * @dev The functionality of cEtherFactory and cErc20Factory lives in separate contracts, instead of directly in
 * this contract, since including them here would put this contract over the size limit
 */
contract ProtectionMarketFactory is ProtectionMarketFactoryErrorReporter {
  /// @notice Address of the comptroller
  ComptrollerInterface public comptroller;

  /// @notice Address of the CEtherFactory contract
  CEtherFactory public cEtherFactory;

  /// @notice Address of the CErc20Factory contract
  CErc20Factory public cErc20Factory;

  /// @notice Mapping of underlying to last-used index for protection token naming
  mapping(address => uint256) public tokenIndices;

  /// @notice Default InterestRateModel assigned to protection markets at deployment
  InterestRateModel public defaultInterestRateModel;

  /// @notice Special address used to represent ETH
  address internal constant ethUnderlyingAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice Number of decimals used for protection market cToken when deployed
  uint8 internal constant decimals = 8;

  /// @notice Prefix to prepend to protection token symbols
  string internal constant tokenSymbolPrefix = "Cozy";

  /// @notice Separator used in protection token symbols
  string internal constant tokenSymbolSeparator = "-";

  /// @notice Indicator that this is ProtectionMarketFactory contract (for inspection)
  bool public constant isProtectionMarketFactory = true;

  /// @notice Emitted when protection market default interest rate model is changed by admin
  event NewDefaultInterestRateModel(InterestRateModel oldModel, InterestRateModel newModel);

  /**
   * @param cEtherFactory_ Address of the CEtherFactory contract
   * @param cErc20Factory_ Address of the CErc20Factory contract
   * @param comptroller_ Address of the system's comptroller
   * @param defaultInterestRateModel_ Address of the default interest rate model to use for new markets
   */
  constructor(
    CEtherFactory cEtherFactory_,
    CErc20Factory cErc20Factory_,
    ComptrollerInterface comptroller_,
    InterestRateModel defaultInterestRateModel_
  ) public {
    cEtherFactory = cEtherFactory_;
    cErc20Factory = cErc20Factory_;
    comptroller = comptroller_;
    require(_setDefaultInterestRateModel(defaultInterestRateModel_) == 0, "Set interest rate model failed");
  }

  /**
   * @notice Deploy a new protection market
   * @dev We could use the Comptroller address in storage instead of requiring it as an input, but passing it as an
   * input makes this contract more flexible, and also saves some gas since address(this) is much cheaper than SLOAD
   * @param _underlying The address of the underlying asset
   * @param _comptroller Address of the system's comptroller
   * @param _admin Address of the administrator of this token
   * @param _trigger Address of the trigger contract
   * @param interestRateModel_ Address of the interest rate model to use, or zero address to use the default
   */
  function deployProtectionMarket(
    address _underlying,
    ComptrollerInterface _comptroller,
    address payable _admin,
    TriggerInterface _trigger,
    address interestRateModel_
  ) external returns (address) {
    require(msg.sender == address(_comptroller), "Caller not authorized");

    // Get initial token symbol, token name, and initial exchange rate
    (string memory symbol, string memory name) = createTokenSymbolAndName(_trigger, _underlying);
    uint256 initialExchangeRateMantissa;
    {
      // Scope to avoid stack too deep errors
      uint256 underlyingDecimals = _underlying == ethUnderlyingAddress ? 18 : EIP20Interface(_underlying).decimals();
      uint256 scale = 18 + underlyingDecimals - decimals;
      initialExchangeRateMantissa = 2 * 10**(scale - 2); // (scale - 2) so initial exchange rate is equivalent to 0.02
    }

    // Deploy market
    if (_underlying == ethUnderlyingAddress) {
      return
        cEtherFactory.deployCEther(
          _comptroller,
          getInterestRateModel(interestRateModel_), // inline helper method to avoid stack too deep errors
          initialExchangeRateMantissa,
          name,
          symbol,
          decimals,
          _admin,
          address(_trigger)
        );
    } else {
      return
        cErc20Factory.deployCErc20(
          _underlying,
          _comptroller,
          getInterestRateModel(interestRateModel_), // inline helper method to avoid stack too deep errors
          initialExchangeRateMantissa,
          name,
          symbol,
          decimals,
          _admin,
          address(_trigger)
        );
    }
  }

  /**
   * @notice Returns the default interest rate model if none was provided
   * @param _interestRateModel Provided interest rate model
   */
  function getInterestRateModel(address _interestRateModel) internal returns (InterestRateModel) {
    return _interestRateModel == address(0) ? defaultInterestRateModel : InterestRateModel(_interestRateModel);
  }

  /**
   * @notice Derive a cToken name and symbol based on the trigger, underlying, and previously deployed markets
   * @dev Used internally in the factory method for creating protection markets
   * @param _trigger The address of the trigger that will be associated with this market
   * @param _underlying The address of the underlying asset used for this cToken
   * @return (symbol, name) The symbol and name for the new cToken, respectively
   */
  function createTokenSymbolAndName(TriggerInterface _trigger, address _underlying)
    internal
    returns (string memory symbol, string memory name)
  {
    // Generate string for index postfix
    uint256 nextIndex = tokenIndices[_underlying] + 1;
    string memory indexString = Strings.toString(nextIndex);

    // Remember that this token index has been used
    tokenIndices[_underlying] = nextIndex;

    // Get symbol for underlying asset
    string memory underlyingSymbol;
    if (_underlying == ethUnderlyingAddress) {
      underlyingSymbol = "ETH";
    } else {
      EIP20Interface underlyingToken = EIP20Interface(_underlying);
      underlyingSymbol = underlyingToken.symbol();
    }

    // Generate token symbol, example "Cozy-DAI-1"
    string memory tokenSymbol =
      string(
        abi.encodePacked(tokenSymbolPrefix, tokenSymbolSeparator, underlyingSymbol, tokenSymbolSeparator, indexString)
      );

    // Generate token name, example "Cozy-DAI-1-Some Protocol Failure"
    string memory tokenName = string(abi.encodePacked(tokenSymbol, tokenSymbolSeparator, _trigger.name()));

    return (tokenSymbol, tokenName);
  }

  /**
   * @notice Sets defaultInterestRateModel
   * @dev Admin function to set defaultInterestRateModel, must be called by Comptroller admin
   * @param _newModel New defaultInterestRateModel
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setDefaultInterestRateModel(InterestRateModel _newModel) public returns (uint256) {
    // Check caller is the Comptroller admin
    if (msg.sender != ComptrollerAdmin(address(comptroller)).admin()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_DEFAULT_INTEREST_RATE_MODEL_OWNER_CHECK);
    }

    // Sanity check the new contract
    if (!_newModel.isInterestRateModel()) {
      return fail(Error.INTEREST_RATE_MODEL_ERROR, FailureInfo.SET_DEFAULT_INTEREST_RATE_MODEL_VALIDITY_CHECK);
    }

    // Emit event with old model, new model
    emit NewDefaultInterestRateModel(defaultInterestRateModel, _newModel);

    // Set default model to the new model
    defaultInterestRateModel = _newModel;

    return uint256(Error.NO_ERROR);
  }
}

/**
 * @notice Simple contract with one method to deploy a new CEther contract with the specified parameters
 */
contract CEtherFactory {
  /**
   * @notice Deploy a new CEther money market or protection market
   * @param comptroller The address of the Comptroller
   * @param interestRateModel The address of the interest rate model
   * @param initialExchangeRateMantissa The initial exchange rate, scaled by 1e18
   * @param name ERC-20 name of this token
   * @param symbol ERC-20 symbol of this token
   * @param decimals ERC-20 decimal precision of this token
   * @param admin Address of the administrator of this token
   * @param trigger Trigger contract address for protection markets, or the zero address for money markets
   */
  function deployCEther(
    ComptrollerInterface comptroller,
    InterestRateModel interestRateModel,
    uint256 initialExchangeRateMantissa,
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address payable admin,
    address trigger
  ) external returns (address) {
    CEther cToken =
      new CEther(comptroller, interestRateModel, initialExchangeRateMantissa, name, symbol, decimals, admin, trigger);

    return address(cToken);
  }
}

/**
 * @notice Simple contract with one method to deploy a new CErc20 contract with the specified parameters
 */
contract CErc20Factory {
  /**
   * @notice Construct a new CErc20 money market or protection market
   * @param underlying The address of the underlying asset
   * @param comptroller The address of the Comptroller
   * @param interestRateModel The address of the interest rate model
   * @param initialExchangeRateMantissa The initial exchange rate, scaled by 1e18
   * @param name ERC-20 name of this token
   * @param symbol ERC-20 symbol of this token
   * @param decimals ERC-20 decimal precision of this token
   * @param admin Address of the administrator of this token
   * @param trigger Trigger contract address for protection markets, or the zero address for money markets
   */
  function deployCErc20(
    address underlying,
    ComptrollerInterface comptroller,
    InterestRateModel interestRateModel,
    uint256 initialExchangeRateMantissa,
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address payable admin,
    address trigger
  ) external returns (address) {
    CErc20Immutable cToken =
      new CErc20Immutable(
        underlying,
        comptroller,
        interestRateModel,
        initialExchangeRateMantissa,
        name,
        symbol,
        decimals,
        admin,
        trigger
      );

    return address(cToken);
  }
}
