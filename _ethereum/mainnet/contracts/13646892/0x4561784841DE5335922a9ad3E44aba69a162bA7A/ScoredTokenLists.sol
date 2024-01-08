// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== Internal Libraries ========== */
import "./ScoreLibrary.sol";

/* ========== Internal Interfaces ========== */
import "./ICirculatingMarketCapOracle.sol";
import "./IScoringStrategy.sol";

/* ========== Internal Inheritance ========== */
import "./OwnableProxy.sol";


/**
 * @title ScoredTokenLists
 * @author d1ll0n
 *
 * @dev This contract stores token lists sorted and filtered using arbitrary scoring strategies.
 *
 * Each token list contains an array of tokens, a scoring strategy address, minimum and maximum
 * scores for the list, and a mapping for which tokens are included.
 *
 * A scoring strategy is a smart contract which implements the `getTokenScores`, which scores
 * tokens using an arbitrary methodology.
 *
 * Token lists are sorted in descending order by the scores returned by the list's scoring strategy,
 * and filtered according to the minimum/maximum scores.
 *
 * The contract owner can create a new token list with a metadata hash used to query
 * additional details about its purpose and inclusion criteria from IPFS.
 *
 * The owner can add and remove tokens from the lists.
 */
contract ScoredTokenLists is OwnableProxy {
  using ScoreLibrary for address[];
  using ScoreLibrary for uint256[];
  using ScoreLibrary for uint256;

/* ==========  Constants  ========== */
  // Maximum number of tokens in a token list
  uint256 public constant MAX_LIST_TOKENS = 25;

  // Uniswap TWAP oracle
  IIndexedUniswapV2Oracle public immutable uniswapOracle;

/* ==========  Events  ========== */

  /** @dev Emitted when a new token list is created. */
  event TokenListAdded(
    uint256 listID,
    bytes32 metadataHash,
    address scoringStrategy,
    uint128 minimumScore,
    uint128 maximumScore
  );

  /** @dev Emitted when a token list is sorted and filtered. */
  event TokenListSorted(uint256 listID);

  /** @dev Emitted when a token is added to a list. */
  event TokenAdded(address token, uint256 listID);

  /** @dev Emitted when a token is removed from a list. */
  event TokenRemoved(address token, uint256 listID);

/* ==========  Structs  ========== */

  /**
   * @dev Token list storage structure.
   * @param minimumScore Minimum market cap for included tokens
   * @param maximumScore Maximum market cap for included tokens
   * @param scoringStrategy Address of the scoring strategy contract used
   * @param tokens Array of included tokens
   * @param isIncludedToken Mapping of included tokens
   */
  struct TokenList {
    uint128 minimumScore;
    uint128 maximumScore;
    address scoringStrategy;
    address[] tokens;
    mapping(address => bool) isIncludedToken;
  }

/* ==========  Storage  ========== */

  // Chainlink or other circulating market cap oracle
  ICirculatingMarketCapOracle public circulatingMarketCapOracle;

  // Number of categories that exist.
  uint256 public tokenListCount;
  mapping(uint256 => TokenList) internal _lists;

/* ========== Modifiers ========== */

  modifier validTokenList(uint256 listID) {
    require(listID <= tokenListCount && listID > 0, "ERR_LIST_ID");
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related contracts.
   */
  constructor(IIndexedUniswapV2Oracle _oracle) public OwnableProxy() {
    uniswapOracle = _oracle;
  }

/* ==========  Configuration  ========== */

  /**
   * @dev Initialize the categories with the owner address.
   * This sets up the contract which is deployed as a singleton proxy.
   */
  function initialize() public virtual {
    _initializeOwnership();
  }

/* ==========  Permissioned List Management  ========== */

  /**
   * @dev Creates a new token list.
   *
   * @param metadataHash Hash of metadata about the token list which can
   * be distributed on IPFS.
   */
  function createTokenList(
    bytes32 metadataHash,
    address scoringStrategy,
    uint128 minimumScore,
    uint128 maximumScore
  )
    external
    onlyOwner
  {
    require(minimumScore > 0, "ERR_NULL_MIN_CAP");
    require(maximumScore > minimumScore, "ERR_MAX_CAP");
    require(scoringStrategy != address(0), "ERR_NULL_ADDRESS");
    uint256 listID = ++tokenListCount;
    TokenList storage list = _lists[listID];
    list.scoringStrategy = scoringStrategy;
    list.minimumScore = minimumScore;
    list.maximumScore = maximumScore;
    emit TokenListAdded(listID, metadataHash, scoringStrategy, minimumScore, maximumScore);
  }

  /**
   * @dev Adds a new token to a token list.
   *
   * @param listID Token list identifier.
   * @param token Token to add to the list.
   */
  function addToken(uint256 listID, address token) external onlyOwner validTokenList(listID) {
    TokenList storage list = _lists[listID];
    require(
      list.tokens.length < MAX_LIST_TOKENS,
      "ERR_MAX_LIST_TOKENS"
    );
    _addToken(list, token);
    uniswapOracle.updatePrice(token);
    emit TokenAdded(token, listID);
  }

  /**
   * @dev Add tokens to a token list.
   *
   * @param listID Token list identifier.
   * @param tokens Array of tokens to add to the list.
   */
  function addTokens(uint256 listID, address[] calldata tokens)
    external
    onlyOwner
    validTokenList(listID)
  {
    TokenList storage list = _lists[listID];
    require(
      list.tokens.length + tokens.length <= MAX_LIST_TOKENS,
      "ERR_MAX_LIST_TOKENS"
    );
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      _addToken(list, token);
      emit TokenAdded(token, listID);
    }
    uniswapOracle.updatePrices(tokens);
  }

  /**
   * @dev Remove token from a token list.
   *
   * @param listID Token list identifier.
   * @param token Token to remove from the list.
   */
  function removeToken(uint256 listID, address token) external onlyOwner validTokenList(listID) {
    TokenList storage list = _lists[listID];
    uint256 i = 0;
    uint256 len = list.tokens.length;
    require(len > 0, "ERR_EMPTY_LIST");
    require(list.isIncludedToken[token], "ERR_TOKEN_NOT_BOUND");
    list.isIncludedToken[token] = false;
    for (; i < len; i++) {
      if (list.tokens[i] == token) {
        uint256 last = len - 1;
        if (i != last) {
          address lastToken = list.tokens[last];
          list.tokens[i] = lastToken;
        }
        list.tokens.pop();
        emit TokenRemoved(token, listID);
        return;
      }
    }
  }

/* ==========  Public List Updates  ========== */

  /**
   * @dev Updates the prices on the Uniswap oracle for all the tokens in a token list.
   */
  function updateTokenPrices(uint256 listID)
    external
    validTokenList(listID)
    returns (bool[] memory pricesUpdated)
  {
    pricesUpdated = uniswapOracle.updatePrices(_lists[listID].tokens);
  }

  /**
   * @dev Returns the tokens and scores in the token list for `listID` after
   * sorting and filtering the tokens according to the list's configuration.
   */
  function sortAndFilterTokens(uint256 listID)
    external
    validTokenList(listID)
  {
    TokenList storage list = _lists[listID];
    address[] memory tokens = list.tokens;
    uint256[] memory marketCaps = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    address[] memory removedTokens = tokens.sortAndFilterReturnRemoved(
      marketCaps,
      list.minimumScore,
      list.maximumScore
    );
    _lists[listID].tokens = tokens;
    for (uint256 i = 0; i < removedTokens.length; i++) {
      address token = removedTokens[i];
      list.isIncludedToken[token] = false;
      emit TokenRemoved(token, listID);
    }
  }


/* ==========  Score Queries  ========== */

  /**
   * @dev Returns the tokens and market caps for `catego
   */
  function getSortedAndFilteredTokensAndScores(uint256 listID)
    public
    view
    validTokenList(listID)
    returns (
      address[] memory tokens,
      uint256[] memory scores
    )
  {
    TokenList storage list = _lists[listID];
    tokens = list.tokens;
    scores = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    tokens.sortAndFilter(
      scores,
      list.minimumScore,
      list.maximumScore
    );
  }

/* ==========  Token List Queries  ========== */

  /**
   * @dev Returns boolean stating whether `token` is a member of the list `listID`.
   */
  function isTokenInlist(uint256 listID, address token)
    external
    view
    validTokenList(listID)
    returns (bool)
  {
    return _lists[listID].isIncludedToken[token];
  }

  /**
   * @dev Returns the array of tokens in a list.
   */
  function getTokenList(uint256 listID)
    external
    view
    validTokenList(listID)
    returns (address[] memory tokens)
  {
    tokens = _lists[listID].tokens;
  }

  /**
   * @dev Returns the top `count` tokens and market caps in the list for `listID`
   * after sorting and filtering the tokens according to the list's configuration.
   */
  function getTopTokensAndScores(uint256 listID, uint256 count)
    public
    view
    validTokenList(listID)
    returns (
      address[] memory tokens,
      uint256[] memory scores
    )
  {
    (tokens, scores) = getSortedAndFilteredTokensAndScores(listID);
    require(count <= tokens.length, "ERR_LIST_SIZE");
    assembly {
      mstore(tokens, count)
      mstore(scores, count)
    }
  }

  /**
   * @dev Query the configuration values for a token list.
   *
   * @param listID Identifier for the token list
   * @return scoringStrategy Address of the scoring strategy contract used
   * @return minimumScore Minimum market cap for an included token
   * @return maximumScore Maximum market cap for an included token
   */
  function getTokenListConfig(uint256 listID)
    external
    view
    validTokenList(listID)
    returns (
      address scoringStrategy,
      uint128 minimumScore,
      uint128 maximumScore
    )
  {
    TokenList storage list = _lists[listID];
    scoringStrategy = list.scoringStrategy;
    minimumScore = list.minimumScore;
    maximumScore = list.maximumScore;
  }

  function getTokenScores(uint256 listID, address[] memory tokens)
    public
    view
    validTokenList(listID)
    returns (uint256[] memory scores)
  {
    scores = IScoringStrategy(_lists[listID].scoringStrategy).getTokenScores(tokens);
  }

/* ==========  Token List Utility Functions  ========== */

  /**
   * @dev Adds a new token to a list.
   */
  function _addToken(TokenList storage list, address token) internal {
    require(!list.isIncludedToken[token], "ERR_TOKEN_BOUND");
    list.isIncludedToken[token] = true;
    list.tokens.push(token);
  }
}

interface IIndexedUniswapV2Oracle {

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory);

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256);

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata ethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory);

  function computeAverageTokensForEth(
    address token,
    uint256 ethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256);
}