//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ICirculatingMarketCapOracle.sol";


/**
 * @dev Contract for querying tokens' circulating market caps from CoinGecko via Chainlink.
 *
 * The contract's owner may whitelist or dewhitelist tokens.
 * Only whitelisted tokens' market caps can be requested from Chainlink.
 * This contract requires LINK to operate and assumes that the owner has supplied it with LINK.
 * If it does not have enough LINK to execute a request, it will revert.
 *
 * Returned market caps are denominated in wei units of USD.
 * Each token's market cap can be queried from Chainlink once every `minimumDelay` seconds.
 * If the last update to the market cap is older than `maximumAge`, queries for the token's
 * market cap will revert.
 */
contract CirculatingMarketCapOracle is Ownable, ChainlinkClient, ICirculatingMarketCapOracle {
  string public constant TOKEN_ADDRESS_BASE_URL = "https://api.coingecko.com/api/v3/simple/token_price/ethereum?contract_addresses=";
  string public constant TOKEN_ID_BASE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=";
  string public constant QUERY_PARAMS = "&vs_currencies=usd&include_market_cap=true";

/* ==========  Events  ========== */

  event TokenAdded(address token);
  event TokenRemoved(address token);
  event NewMinimumDelay(uint256 minimumDelay);
  event NewMaximumAge(uint256 maximumAge);
  event NewRequestTimeout(uint256 requestTimeout);
  event NewChainlinkFee(uint256 fee);
  event NewJobID(bytes32 jobID);
  event TokenOverrideAdded(address token, string overrideID);
  event TokenOverrideRemoved(address token);

/* ==========  Structs  ========== */

  struct TokenDetails {
    bool whitelisted;
    bool hasPendingRequest;
    bool useOverride;
    uint32 lastPriceTimestamp;
    uint32 lastRequestTimestamp;
    uint168 marketCap;
  }

/* ==========  Storage  ========== */

  /** @dev Minimum delay between Chainlink queries for a token's market cap */
  uint256 public minimumDelay;
  /** @dev Maximum age of a market cap value that can be queried */
  uint256 public maximumAge;
  /** @dev Maximum age of a request before allowing the query to be retried. */
  uint256 public requestTimeout;
  /** @dev Amount of LINK paid for each query */
  uint256 public fee = 4e17; // 0.4 LINK
  /** @dev Address of the Chainlink node */
  address public oracle;
  /** @dev Chainlink job ID */
  bytes32 public jobID;

  /** @dev Records for token approval, market cap and status. */
  mapping(address => TokenDetails) public getTokenDetails;
  /** @dev Records of which addresses are associated with pending requests. */
  mapping(bytes32 => address) public pendingRequestMap;
  /** @dev Used for wrapper tokens to query the base asset instead of the erc20. */
  mapping(address => string) public tokenOverrideIDs;

  /**
  * @dev Constructor
  * @param _minimumDelay Minimum delay in seconds before token price can be updated again.
  * @param _maximumAge Maximum age of a market cap record that can be queried.
  * @param _requestTimeout Maximum age of a request before allowing the query to be retried.
  * @param _oracle Chainlink oracle address.
  * @param _jobID Chainlink job id.
  * @param _link Chainlink token address.
  */
  constructor(
    uint256 _minimumDelay,
    uint256 _maximumAge,
    uint256 _requestTimeout,
    address _oracle,
    bytes32 _jobID,
    address _link
  ) public Ownable() {
    minimumDelay = _minimumDelay;
    maximumAge = _maximumAge;
    requestTimeout = _requestTimeout;
    oracle = _oracle;
    jobID = _jobID;
    setChainlinkToken(_link);
  }

/* ==========  Public Actions  ========== */

  /**
   * @dev Requests the market caps for a set of tokens from Chainlink.
   *
   * Note: If token is not whitelisted, this function will revert.
   * If the token already has a pending request, or the last update is too
   * recent, this will not revert but a new request will not be created.
   */
  function updateCirculatingMarketCaps(address[] calldata _tokenAddresses) external override {
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      address token = _tokenAddresses[i];
      TokenDetails storage details = getTokenDetails[token];
      // If token is not whitelisted, don't pay to update it.
      require(details.whitelisted, "CirculatingMarketCapOracle: Token is not whitelisted");
      // If token already has a pending update request, or the last update is too
      // new, fail gracefully.
      if (
        details.hasPendingRequest ||
        now - details.lastPriceTimestamp < minimumDelay
      ) {
        continue;
      }
      details.hasPendingRequest = true;
      details.lastRequestTimestamp = uint32(now);
      // Execute Chainlink request
      bytes32 requestId = requestCoinGeckoData(_tokenAddresses[i]);
      // Map requestId to the token address
      pendingRequestMap[requestId] = token;
    }
  }

  /**
   * @dev Cancel an expired request by setting `hasPendingRequest` to false.
   *
   * Note: Does not actually cancel the request on Chainlink, only marks the
   * token as not having a pending request so it can be queried again.
   */
  function cancelExpiredRequest(address token) external {
    TokenDetails storage details = getTokenDetails[token];
    require(
      details.hasPendingRequest &&
      now - details.lastRequestTimestamp >= requestTimeout,
      "CirculatingMarketCapOracle: Request has not expired or does not exist"
    );
    details.hasPendingRequest = false;
  }

/* ==========  Market Cap Queries  ========== */

  /**
   * @dev Query the latest circulating market caps for a set of tokens.
   *
   * Note: Reverts if any of the tokens has no stored market cap or if the last
   * market cap is older than `maximumAge` seconds.
   *
   * @param tokens Addresses of tokens to get market caps for.
   * @return marketCaps Array of latest markets cap for tokens
   */
  function getCirculatingMarketCaps(address[] calldata tokens)
    external
    view
    override
    returns (uint256[] memory marketCaps)
  {
    uint256 len = tokens.length;
    marketCaps = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      marketCaps[i] = getCirculatingMarketCap(tokens[i]);
    }
  }

  /**
   * @dev Query the latest circulating market cap for a token.
   *
   * Note: Reverts if the token has no stored market cap or if the last
   * market cap is older than `maximumAge` seconds.
   *
   * @param token Address of token to get market cap for.
   * @return uint256 of latest market cap for token
   */
  function getCirculatingMarketCap(address token) public view override returns (uint256) {
    require(
      now - getTokenDetails[token].lastPriceTimestamp < maximumAge,
      "CirculatingMarketCapOracle: Marketcap has expired"
    );

    return getTokenDetails[token].marketCap;
  }

  /**
   * @dev Check if a token is whitelisted.
   * @param token Address to check
   * @return boolean indicating whether token is whitelisted
   */
  function isTokenWhitelisted(address token) external view override returns (bool) {
    return getTokenDetails[token].whitelisted;
  }

/* ==========  Chainlink Functions  ========== */

  /**
  * @dev Create a Chainlink request to retrieve API response, find the target
  * data, then multiply 1e18 to normalize the value as a token amount.
  *
  * CoinGecko API Example:
  * {
  *   '0x514910771af9ca656af840dff83e8264ecf986ca': {
  *   'usd': 23.01,
  *   'usd_market_cap': 9362732898.302298
  *     }
  *   }
  *
  * https://docs.chain.link/docs/make-a-http-get-request#api-consumer
  *
  * @param _token Address of the token to query the circulating market cap of.
  * @return requestId The request id for the node operator
  */
  function requestCoinGeckoData(address _token) internal virtual returns (bytes32 requestId) {
    Chainlink.Request memory request = buildChainlinkRequest(
      jobID,
      address(this),
      this.fulfill.selector
    );

    // Build the CoinGecko request URL
    (string memory url, string memory tokenKey) = getCoingeckoMarketCapUrlAndKey(_token);

    // Set the request object to perform a GET request with the constructed URL
    request.add("get", url);

    // Build path to parse JSON response from CoinGecko
    // e.g. '0x514910771af9ca656af840dff83e8264ecf986ca.usd_market_cap'
    string memory pathString = string(abi.encodePacked(tokenKey, ".usd_market_cap"));
    request.add("path", pathString);

    // Multiply by 1e18 to format the number as a typical token value.
    request.addInt("times", 1e18);

    // Sends the request
    requestId = sendChainlinkRequestTo(oracle, request, fee);
  }

  /**
  * @dev Callback function for Chainlink node.
  * Updates the token mapping and removes the request from pendingRequestMap
  */
  function fulfill(bytes32 _requestId, uint256 _marketCap) external virtual recordChainlinkFulfillment(_requestId) {
    // Wraps the internal function to simplify automated testing with mocks.
    _fulfill(_requestId, _marketCap);
  }

  function _fulfill(bytes32 _requestId, uint256 _marketCap) internal {
    address token = pendingRequestMap[_requestId];

    TokenDetails storage details = getTokenDetails[token];
    details.lastPriceTimestamp = uint32(now);
    details.marketCap = _safeUint168(_marketCap);
    details.hasPendingRequest = false;

    delete pendingRequestMap[_requestId];
  }

/* ==========  Control Functions  ========== */

  /**
   * @dev Withdraw Link tokens in contract to owner address
   */
  function withdrawLink() external onlyOwner {
    IERC20 linkToken = IERC20(chainlinkTokenAddress());
    linkToken.transfer(owner(), linkToken.balanceOf(address(this)));
  }

  /**
   * @dev Whitelist a list of token addresses
   */
  function addTokensToWhitelist(address[] calldata _tokens) external onlyOwner {
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      address token = _tokens[i];
      getTokenDetails[token].whitelisted = true;
      emit TokenAdded(token);
    }
  }

  /**
   * @dev Remove a list of token addresses from whitelist
   */
  function removeTokensFromWhitelist(address[] calldata _tokens) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++){
      address token = _tokens[i];
      getTokenDetails[token].whitelisted = false;
      emit TokenRemoved(token);
    }
  }

  /**
   * @dev Change minimumDelay
   */
  function setMinimumDelay(uint256 _newDelay) external onlyOwner {
    minimumDelay = _newDelay;
    emit NewMinimumDelay(_newDelay);
  }

  /**
   * @dev Change maximumAge
   */
  function setMaximumAge(uint256 _maximumAge) external onlyOwner {
    maximumAge = _maximumAge;
    emit NewMaximumAge(_maximumAge);
  }

  /**
   * @dev Change requestTimeout
   */
  function setRequestTimeout(uint256 _requestTimeout) external onlyOwner {
    requestTimeout = _requestTimeout;
    emit NewRequestTimeout(_requestTimeout);
  }

  /**
  * @dev Changes the chainlink node operator fee to be sent
  */
  function setChainlinkNodeFee(uint256 _fee) external onlyOwner {
    fee = _fee;
    emit NewChainlinkFee(_fee);
  }

  /**
  * @dev Changes the chainlink job ID
  */
  function setJobID(bytes32 _jobID) external onlyOwner {
    jobID = _jobID;
    emit NewJobID(_jobID);
  }

  /**
   * @dev Sets an override ID to use for a token instead of its address.
   * Note: This will change the API query used to get the market cap.
   */
  function setTokenOverrideID(address token, string calldata overrideID) external onlyOwner {
    TokenDetails storage details = getTokenDetails[token];
    if (bytes(overrideID).length == 0) {
      details.useOverride = false;
      delete tokenOverrideIDs[token];
      emit TokenOverrideRemoved(token);
    } else {
      details.useOverride = true;
      tokenOverrideIDs[token] = overrideID;
      emit TokenOverrideAdded(token, overrideID);
    }
  }

/* ==========  Utility Functions  ========== */

  /**
   * @dev Internal function to convert an address to a string memory
   */
  function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2*i + 2] = alphabet[uint8(value[i + 12] >> 4)];
      str[2*i + 3] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  function getCoingeckoMarketCapUrlAndKey(address token)
    public
    view
    returns (string memory url, string memory tokenKey)
  {
    TokenDetails storage details = getTokenDetails[token];
    if (details.useOverride) {
      tokenKey = tokenOverrideIDs[token];
      url = string(
        abi.encodePacked(
          TOKEN_ID_BASE_URL,
          tokenKey,
          QUERY_PARAMS
        )
      );
    } else {
      tokenKey = addressToString(token);
      url = string(
        abi.encodePacked(
          TOKEN_ADDRESS_BASE_URL,
          tokenKey,
          QUERY_PARAMS
        )
      );
    }
  }

  function _safeUint168(uint256 x) internal pure returns (uint168 y) {
    y = uint168(x);
    require(x == y, "CirculatingMarketCapOracle: uint exceeds 168 bits");
  }
}
