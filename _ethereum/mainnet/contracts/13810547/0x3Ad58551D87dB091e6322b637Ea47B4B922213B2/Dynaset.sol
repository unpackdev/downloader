// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== Internal Inheritance ========== */
import "./DToken.sol";
import "./BMath.sol";

/* ========== Internal Interfaces ========== */
import "./IDynaset.sol";
import "./IUniswapV2Router.sol";
import "./OneInchAgregator.sol";


/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license 
*************************************************************************************************/


contract Dynaset is DToken, BMath, IDynaset {

/* ==========  EVENTS  ========== */

  /** @dev Emitted when tokens are swapped. */
  event LOG_SWAP(
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 Amount
  );

  /** @dev Emitted when underlying tokens are deposited for dynaset tokens. */
  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  /** @dev Emitted when dynaset tokens are burned for underlying. */
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
  ) anonymous;

  /** @dev Emitted when a token's weight updates. */
  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

/* ==========  Modifiers  ========== */
  
  modifier _logs_() {
      emit LOG_CALL(msg.sig, msg.sender, msg.data);
      _;
  }

  modifier _lock_ {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, "ERR_REENTRY");
    _;
  }

  modifier _control_ {
    require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    _;
  }

  modifier _digital_asset_managers_ {
    require(msg.sender == _digital_asset_manager, "ERR_NOT_DAM");
    _;
  }

  modifier _mint_forge_ {
    require(_mint_forges[msg.sender], "ERR_NOT_FORGE");
    _;
  }

  modifier _burn_forge_ {
     require(_burn_forges[msg.sender], "ERR_NOT_FORGE");
    _;
  }

  /* uniswap addresses*/

  //address of the uniswap v2 router
  address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  //address of the oneInch v3 aggregation router
  address private constant ONEINCH_V4_AGREGATION_ROUTER = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    //address of WETH token.  This is needed because some times it is better to trade through WETH.
    //you might get a better price using WETH.
    //example trading from token A to WETH then WETH to token B might result in a better price
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

/* ==========  Storage  ========== */
  
  bool internal _mutex;
  // Account with CONTROL role. Able to modify the swap fee,
  // adjust token weights, bind and unbind tokens and lock
  // public swaps & joins.
  address internal _controller;

  address internal _digital_asset_manager;

  mapping(address =>bool) internal _mint_forges;
  mapping(address =>bool) internal _burn_forges;


  // Array of underlying tokens in the dynaset.
  address[] internal _tokens;

  // Internal records of the dynaset's underlying tokens
  mapping(address => Record) internal _records;

  // Total denormalized weight of the dynaset.
  uint256 internal _totalWeight;


  constructor() public {
      _controller = msg.sender;
  }

/* ==========  Controls  ========== */

  /**
   * @dev Sets the controller address and the token name & symbol.
   *
   * Note: This saves on storage costs for multi-step dynaset deployment.
   *
   * @param controller Controller of the dynaset
   * @param name Name of the dynaset token
   * @param symbol Symbol of the dynaset token
   */
  function configure(
    address controller,//admin
    address dam,//digital asset manager
    string calldata name,
    string calldata symbol
  ) external override  _control_{
    _controller = controller;
    _digital_asset_manager = dam;
    _initializeToken(name, symbol);
  }

    /**
   * @dev Sets up the initial assets for the pool.
   *
   * Note: `tokenProvider` must have approved the pool to transfer the
   * corresponding `balances` of `tokens`.
   *
   * @param tokens Underlying tokens to initialize the pool with
   * @param balances Initial balances to transfer
   * @param denorms Initial denormalized weights for the tokens
   * @param tokenProvider Address to transfer the balances from
   */
  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider
  )
    external
    override
    _control_
  {
    require(_tokens.length == 0, "ERR_INITIALIZED");
    uint256 len = tokens.length;
    require(len > 1, "ERR_MIN_TOKENS");
    require(len <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
    require(balances.length == len && denorms.length == len, "ERR_ARR_LEN");
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint96 denorm = denorms[i];
      uint256 balance = balances[i];
      require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
      require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
      require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

      _records[token] = Record({
        bound: true,
        ready: true,
        index: uint8(i),
        denorm: denorm,
        balance: balance
      });

      _tokens.push(token);
      
      totalWeight = badd(totalWeight, denorm);
      _pullUnderlying(token, tokenProvider, balance);
    }
    require(totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
    _totalWeight = totalWeight;
    _mintdynasetShare(INIT_POOL_SUPPLY);
    _pushdynasetShare(tokenProvider, INIT_POOL_SUPPLY);
  }

    /**
   * @dev Get all bound tokens.
   */
  function getCurrentTokens()
    public
    view
    override
    returns (address[] memory tokens)
  {
    tokens = _tokens;
  }

  /**
   * @dev Returns the list of tokens which have a desired weight above 0.
   * Tokens with a desired weight of 0 are set to be phased out of the dynaset.
   */
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
      if (_records[token].denorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly { mstore(tokens, usedIndex) }
  }

   /**
   * @dev Returns the denormalized weight of a bound token.
   */
  function getDenormalizedWeight(address token)
    external
    view
    override
    returns (uint256/* denorm */)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    return _records[token].denorm;
  }

  function getNormalizedWeight(address token)
        external 
        view
        _viewlock_
        returns (uint)
  {
    require(_records[token].bound, "ERR_NOT_BOUND");
    uint denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

    /**
   * @dev Get the total denormalized weight of the dynaset.
   */
  function getTotalDenormalizedWeight()
    external
    view
    override
    returns (uint256)
  {
    return _totalWeight;
  }

  /**
   * @dev Returns the stored balance of a bound token.
   */
    function getBalance(address token) external view override returns (uint256) {
      Record storage record = _records[token];
      require(record.bound, "ERR_NOT_BOUND");
      return record.balance;
    }

      /**
     * @dev Sets the desired weights for the pool tokens, which
     * will be adjusted over time as they are swapped.
     *
     * Note: This does not check for duplicate tokens or that the total
     * of the desired weights is equal to the target total weight (25).
     * Those assumptions should be met in the controller. Further, the
     * provided tokens should only include the tokens which are not set
     * for removal.
     */
    function reweighTokens(
      address[] calldata tokens,
      uint96[] calldata Denorms
    )
      external
      override
      _lock_
      _control_
    {
      for (uint256 i = 0; i < tokens.length; i++){
        require(_records[tokens[i]].bound, "ERR_NOT_BOUND");
        _setDesiredDenorm(tokens[i], Denorms[i]);
      }
    }

    // Absorb any tokens that have been sent to this contract into the dynaset
  function updateAfterSwap(address _tokenIn,address _tokenOut) external _digital_asset_managers_{ //external for test

     uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this)); 
     uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
     _records[_tokenIn].balance = balance_in;
     _records[_tokenOut].balance = balance_out;
  
  }


/* ==========  Liquidity Provider Actions  ========== */

  /*
   * @dev Mint new dynaset tokens by providing the proportional amount of each
   * underlying token's balance relative to the proportion of dynaset tokens minted.
   *
   *
   * @param dynasetAmountOut Amount of dynaset tokens to mint
   * @param maxAmountsIn Maximum amount of each token to pay in the same
   * order as the dynaset's _tokens list.
   */

  function joinDynaset(uint256 _amount) external override _mint_forge_{

    uint256[] memory maxAmountsIn = new uint256[](getCurrentTokens().length);
    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      maxAmountsIn[i] = uint256(-1);
    }
    _joinDynaset(_amount, maxAmountsIn);
  }

  function _joinDynaset(uint256 dynasetAmountOut, uint256[] memory maxAmountsIn)
   internal 
   //external
   //override
  {
    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(dynasetAmountOut, dynasetTotal); 
    require(ratio != 0, "ERR_MATH_APPROX");
    require(maxAmountsIn.length == _tokens.length, "ERR_ARR_LEN");

    for (uint256 i = 0; i < maxAmountsIn.length; i++) {
      address t = _tokens[i];
      (, uint256 realBalance) = _getInputToken(t);
      //uint256 bal = getBalance(t);
      uint256 tokenAmountIn = bmul(ratio, realBalance);
      require(tokenAmountIn != 0, "ERR_MATH_APPROX");
      require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
     
      _updateInputToken(t, badd(realBalance, tokenAmountIn));
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }

    _mintdynasetShare(dynasetAmountOut);
    _pushdynasetShare(msg.sender, dynasetAmountOut);
  }


  /*
   * @dev Burns `dynasetAmountIn` dynaset tokens in exchange for the amounts of each
   * underlying token's balance proportional to the ratio of tokens burned to
   * total dynaset supply. The amount of each token transferred to the caller must
   * be greater than or equal to the associated minimum output amount from the
   * `minAmountsOut` array.
   *
   * @param dynasetAmountIn Exact amount of dynaset tokens to burn
   * @param minAmountsOut Minimum amount of each token to receive, in the same
   * order as the dynaset's _tokens list.
   */
  
  function exitDynaset(uint256 _amount) external override _burn_forge_ {
    uint256[] memory minAmountsOut = new uint256[](getCurrentTokens().length);
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      minAmountsOut[i] = 0;
    }
    _exitDynaset(_amount, minAmountsOut);
  }

  function _exitDynaset(uint256 dynasetAmountIn, uint256[] memory minAmountsOut)
   internal
  {
    require(minAmountsOut.length == _tokens.length, "ERR_ARR_LEN");
    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(dynasetAmountIn, dynasetTotal);
    require(ratio != 0, "ERR_MATH_APPROX");

    _pulldynasetShare(msg.sender, dynasetAmountIn);
    _burndynasetShare(dynasetAmountIn);
    
    for (uint256 i = 0; i < minAmountsOut.length; i++) {
      address t = _tokens[i];
      Record memory record = _records[t];
       if (record.ready) {
        uint256 tokenAmountOut = bmul(ratio, record.balance);
        require(tokenAmountOut != 0, "ERR_MATH_APPROX");
        require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
   
        _records[t].balance = bsub(record.balance, tokenAmountOut);
        emit LOG_EXIT(msg.sender, t, tokenAmountOut);
        _pushUnderlying(t, msg.sender, tokenAmountOut);
       
        }else{
           require(minAmountsOut[i] == 0, "ERR_OUT_NOT_READY");
        }
      
      } 
    
  }



/* ==========  Other  ========== */

  /**
   * @dev Absorb any tokens that have been sent to the dynaset.
   * If the token is not bound, it will be sent to the unbound
   * token handler.
   */

/* ==========  Token Swaps  ========== */
  
  function ApproveOneInch(address token,uint256 amount) external _digital_asset_managers_ {
      
      require(_records[token].bound, "ERR_NOT_BOUND");
      IERC20(token).approve(ONEINCH_V4_AGREGATION_ROUTER, amount);
  }
  

  function swapUniswap(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOutMin) 
  external
  _digital_asset_managers_
  {
        
    require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
    require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
    IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
    } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
    IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
      _amountIn,
      _amountOutMin,
      path,
      address(this),
      block.timestamp
      );

      uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
     
      uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
   
     _records[_tokenIn].balance = balance_in;
     _records[_tokenOut].balance = balance_out;
  }

  //swap using oneinch api
  
  function swapOneInch(
    address _tokenIn,
    address _tokenOut,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata _data) 
  external 
  _digital_asset_managers_ 
  {
      
  require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
  require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
     
  OneInchAgregator(ONEINCH_V4_AGREGATION_ROUTER).unoswap(_tokenIn,amount,minReturn,_data);
    
  uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
  uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
  _records[_tokenIn].balance = balance_in;
  _records[_tokenOut].balance = balance_out;

  emit LOG_SWAP(_tokenIn,_tokenOut,amount);

  }

  function swapOneInchUniV3(
    address _tokenIn,
    address _tokenOut,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata _pools) 
  external 
  _digital_asset_managers_ 
  {
      
  require(_records[_tokenIn].bound, "ERR_NOT_BOUND");
  require(_records[_tokenOut].bound, "ERR_NOT_BOUND");
   
  OneInchAgregator(ONEINCH_V4_AGREGATION_ROUTER).uniswapV3Swap(amount,minReturn,_pools);
    
  uint256 balance_in = IERC20(_tokenIn).balanceOf(address(this));
  uint256 balance_out = IERC20(_tokenOut).balanceOf(address(this));
     
  _records[_tokenIn].balance = balance_in;
  _records[_tokenOut].balance = balance_out;

  emit LOG_SWAP(_tokenIn,_tokenOut,amount);

  }

/* ==========  Config Queries  ========== */
  
  function setMintForge(address _mintForge) external  _control_ returns(address) {
    require (!_mint_forges[_mintForge],"forge already added");
    _mint_forges[_mintForge] = true;
  }

  function setBurnForge(address _burnForge) external _control_ returns(address) {
    require (!_burn_forges[_burnForge],"forge already added");
    _burn_forges[_burnForge] = true;
  }

   function removeMintForge(address _mintForge) external  _control_ returns(address) {
    require (_mint_forges[_mintForge],"not forge ");
    delete _mint_forges[_mintForge];
  }

  function removeBurnForge(address _burnForge) external _control_ returns(address) {
    require (_burn_forges[_burnForge],"not forge ");
    delete _burn_forges[_burnForge];
  }

  

  /**
   * @dev Returns the controller address.
   */
  function getController() external view override returns (address) {
    return _controller;
  }

/* ==========  Token Queries  ========== */

  /**
   * @dev Check if a token is bound to the dynaset.
   */
  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  /**
   * @dev Get the number of tokens bound to the dynaset.
   */
  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  /**
   * @dev Returns the record for a token bound to the dynaset.
   */
  function getTokenRecord(address token)
    external
    view
    override
    returns (Record memory record)
  {
    record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");
  }


/* ==========  Price Queries  ========== */


  function _setDesiredDenorm(address token, uint96 Denorm) internal {
    Record storage record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");
    // If the desired weight is 0, this will trigger a gradual unbinding of the token.
    // Therefore the weight only needs to be above the minimum weight if it isn't 0.
    require(
      Denorm >= MIN_WEIGHT || Denorm == 0,
      "ERR_MIN_WEIGHT"
    );
    require(Denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
    record.denorm = Denorm;
    emit LOG_DENORM_UPDATED(token,Denorm);

  }


/* ==========  dynaset Share Internal Functions  ========== */

  function _pulldynasetShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  function _pushdynasetShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  function _mintdynasetShare(uint256 amount) internal {
    _mint(amount);
  }

  function _burndynasetShare(uint256 amount) internal {
    _burn(amount);
  }

/* ==========  Underlying Token Internal Functions  ========== */
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(
    address erc20,
    address from,
    uint256 amount
  ) internal {

    IERC20(erc20).transferFrom(from,address(this),amount);
  }


  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {

    IERC20(erc20).transfer(to ,amount);

  }


  function withdrawAnyTokens(address token,uint256 amount) 
  external 
  _control_ {
    IERC20 Token = IERC20(token);
   // uint256 currentTokenBalance = Token.balanceOf(address(this));
    Token.transfer(msg.sender, amount); 
  }


/* ==========  Token Management Internal Functions  ========== */

  /** 
   * @dev Handles weight changes and initialization of an
   * input token.
   *
   * If the token is not initialized and the new balance is
   * still below the minimum, this will not do anything.
   *
   * If the token is not initialized but the new balance will
   * bring the token above the minimum balance, this will
   * mark the token as initialized, remove the minimum
   * balance and set the weight to the minimum weight plus
   * 1%.
   *
   *
   * @param token Address of the input token
   * and weight if the token was uninitialized.
   */
  function _updateInputToken(
    address token,
    uint256 realBalance
  )
    internal
  {
      // If the token is still not ready, do not adjust the weight.
    _records[token].balance = realBalance;

  }


/* ==========  Token Query Internal Functions  ========== */

  /**
   * @dev Get the record for a token which is being swapped in.
   * The token must be bound to the dynaset. If the token is not
   * initialized (meaning it does not have the minimum balance)
   * this function will return the actual balance of the token
   * which the dynaset holds, but set the record's balance and weight
   * to the token's minimum balance and the dynaset's minimum weight.
   * This allows the token swap to be priced correctly even if the
   * dynaset does not own any of the tokens.
   */
   function _getInputToken(address token)
    internal
    view
    returns (Record memory record, uint256 realBalance)
  {
    record = _records[token];
    require(record.bound, "ERR_NOT_BOUND");

    realBalance = record.balance;

  }



  function calcTokensForAmount(uint256 _amount)
    external
    view
    returns (address[] memory tokens, uint256[] memory amounts)
  {

    uint256 dynasetTotal = totalSupply();
    uint256 ratio = bdiv(_amount, dynasetTotal);
    require(ratio != 0, "ERR_MATH_APPROX");
    // Underlying_token_amount = Ratio * token_balance_in_dynaset
    //   Ratio  = User_amount / Dynaset_token_supply 
    tokens = _tokens;
    amounts = new uint256[](_tokens.length);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = tokens[i];
      (Record memory record, ) = _getInputToken(t);
      uint256 tokenAmountIn = bmul(ratio, record.balance);
      amounts[i] = tokenAmountIn;
    }
  }

}

