// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IRestrictedIndexPool.sol";

abstract contract IndexPoolBase is IRestrictedIndexPool {
  uint256 internal constant BONE = 10**18;
  uint8 public constant override decimals = 18;

  /* Storage */

  mapping(address => uint256) public override balanceOf;

  mapping(address => mapping(address => uint256)) public override allowance;

  uint256 public override totalSupply;

  string public override name;

  string public override symbol;

  bool internal _mutex;

  address public override getController;

  address internal _unbindHandler;

  bool public override isPublicSwap;

  uint256 public override getSwapFee;

  address[] internal _tokens;

  mapping(address => Record) internal _records;

  uint256 public override getTotalDenormalizedWeight;

  mapping(address => uint256) internal _minimumBalances;

  address public override getExitFeeRecipient;

  address public pair;

  /* View function constants */

  uint256 public constant override getExitFee = 0;

  modifier _lock_ {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _initialized_ {
    require(pair != address(0), "ERR_NOT_INITIALIZED");
    _;
  }

  function initialize(address _uniBurn, address _pair) external override {
    require(pair == address(0), "ERR_INITIALIZED");
    address[] memory tokens = _tokens;
    for (uint256 i; i < tokens.length; i++) {
      address token = tokens[i];
      require(
        IERC20(token).balanceOf(address(this)) >= _records[token].balance,
        "Balances not reinstated"
      );
    }
    balanceOf[_uniBurn] = balanceOf[_pair];
    balanceOf[_pair] = 0;
    pair = _pair;
  }

  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens()
    external
    view
    override
    returns (address[] memory tokens)
  {
    tokens = _tokens;
  }

  function getCurrentDesiredTokens()
    external
    view
    override
    returns (address[] memory tokens)
  {
    address[] memory tempTokens = _tokens;
    tokens = new address[](tempTokens.length);
    uint256 usedIndex = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tempTokens[i];
      if (_records[token].desiredDenorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly {
      mstore(tokens, usedIndex)
    }
  }

  function getDenormalizedWeight(address token)
    external
    view
    override
    returns (
      uint256 /* denorm */
    )
  {
    return getTokenRecord(token).denorm;
  }

  function getTokenRecord(address token)
    public
    view
    override
    returns (Record memory record)
  {
    record = _records[token];
    record.balance = IERC20(token).balanceOf(address(this));
    require(record.bound, "ERR_NOT_BOUND");
  }

  function getBalance(address token) external view override returns (uint256) {
    return getTokenRecord(token).balance;
  }

  function getUsedBalance(address token)
    external
    view
    override
    returns (uint256)
  {
    Record memory record = getTokenRecord(token);
    require(record.bound, "ERR_NOT_BOUND");
    if (!record.ready) {
      return _minimumBalances[token];
    }
    return record.balance;
  }
}
