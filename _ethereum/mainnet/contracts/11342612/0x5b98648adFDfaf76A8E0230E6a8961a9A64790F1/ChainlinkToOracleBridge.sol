pragma solidity 0.6.12;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./IMedianOracle.sol";

/**
 * @title ChainlinkToOracleBridge requests data from the Chainlink network and feeds it to xBTCs 
 * Dominance Oracle
 * @dev This contract is designed to work on multiple networks, including local test networks
 */
contract ChainlinkToOracleBridge is ChainlinkClient, Ownable {
  uint256 public data;

  // details where and how to publish reports to the xBTC oracle
  IMedianOracle public oracle = IMedianOracle(0);
  uint32 public precisionReductionDecimals = 0;

  // details where and how to find the chainlink data
  bytes32 public chainlinkJobId;

  // Addresses of providers authorized to push reports.
  mapping (address => bool) public providers;


  event ProviderAdded(address provider);
  event ProviderRemoved(address provider);
  event OracleSet(IMedianOracle oracle);
  event PrecisionReductionDecimalsSet(uint32 decimals);
  event ChainlinkJobIdSet(bytes32 chainlinkJobId);


  /**
   * @notice Deploy the contract with a specified address for the LINK and Oracle contract addresses
   * @dev Sets the storage for the specified addresses
   * @param _link The address of the LINK token contract
   */
  constructor(address _link, address _chainlinkOracle, bytes32 _chainlinkJobId) public {
    setChainlinkOracle(_chainlinkOracle);
    chainlinkJobId = _chainlinkJobId;

    if (_link == address(0)) {
      setPublicChainlinkToken();
    } else {
      setChainlinkToken(_link);
    }
  }


  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  /**
   * @notice Creates a request to the specified Oracle contract address
   */
  function createRequest(uint256 _payment)
    public
    onlyProvider
    returns (bytes32 requestId)
  {
    Chainlink.Request memory req = buildChainlinkRequest(
      chainlinkJobId, 
      address(this), 
      this.fulfill.selector
      );
    requestId = sendChainlinkRequest(req, _payment);
  }

  /**
   * @notice The fulfill method from requests created by this contract
   * @dev The recordChainlinkFulfillment protects this function from being called
   * by anyone other than the oracle address that the request was sent to
   * @param _requestId The ID that was generated for the request
   * @param _data The answer provided by the oracle
   */
  function fulfill(bytes32 _requestId, uint256 _data)
    public
    recordChainlinkFulfillment(_requestId)
  {
    // modify the data to fit our parameters
    _data = _data / 10**uint128(precisionReductionDecimals);

    // store the data for debugging purposes
    data = _data;

    // send the data to the xBTC oracle, if applicable
    if (address(oracle) != address(0)) {
      oracle.pushReport(_data);
    }
  }

  /**
   * @notice Allows the owner to withdraw any LINK balance on the contract
   */
  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  /**
   * @notice Call this method if no response is received within 5 minutes
   * @param _requestId The ID that was generated for the request to cancel
   * @param _payment The payment specified for the request to cancel
   * @param _callbackFunctionId The bytes4 callback function ID specified for
   * the request to cancel
   * @param _expiration The expiration generated for the request to cancel
   */
  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  /**
   * @dev Throws if called by any account other than a provider.
   */
  modifier onlyProvider() {
    require(providers[_msgSender()], "caller is not a provider");
    _;
  }

  /**
   * @notice Authorizes a provider.
   * @param provider Address of the provider.
   */
  function addProvider(address provider)
    external
    onlyOwner
  {
    require(!providers[provider]);
    providers[provider] = true;
    emit ProviderAdded(provider);
  }

  /**
   * @notice Changes the Chainlink oracle.
   * @param _chainlinkOracle Address of the new oracle.
   */
  function setChainlinkOracleExternal(address _chainlinkOracle)
    external
    onlyOwner
  {
    setChainlinkOracle(_chainlinkOracle);
  }

  /**
   * @notice Revokes provider authorization.
   * @param provider Address of the provider.
   */
  function removeProvider(address provider)
    external
    onlyOwner
  {
    require(providers[provider]);
    delete providers[provider];
    emit ProviderRemoved(provider);
  }

  /**
   * @notice Changes the xBTC dominance oracle
   * @param _oracle Address of the new oracle
   */
  function setOracle(IMedianOracle _oracle)
    external
    onlyOwner
  {
    require(oracle != _oracle);
    oracle = _oracle;
    emit OracleSet(_oracle);
  }

  /**
   * @notice Changes the xBTC dominance oracle precision reduction decimals
   * @param _precisionReductionDecimals How many decimals to reduce
   */
  function setPrecisionReductionDecimals(uint32 _precisionReductionDecimals)
    external
    onlyOwner
  {
    require(precisionReductionDecimals != _precisionReductionDecimals);
    precisionReductionDecimals = _precisionReductionDecimals;
    emit PrecisionReductionDecimalsSet(_precisionReductionDecimals);
  }

  /**
   * @notice Set the chainlink job id for Chainlink requests
   * @param _chainlinkJobId The new chainlink job id
   */
  function setChainlinkJobId(bytes32 _chainlinkJobId)
    external
    onlyOwner
  {
    require(chainlinkJobId != _chainlinkJobId);
    chainlinkJobId = _chainlinkJobId;
    emit ChainlinkJobIdSet(_chainlinkJobId);
  }
}
