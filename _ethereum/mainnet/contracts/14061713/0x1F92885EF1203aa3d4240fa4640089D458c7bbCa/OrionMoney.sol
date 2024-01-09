// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ConversionPool.sol";
import "./ExchangeRateFeeder.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./Math.sol";

import "./StableRateFeeder.sol";
import "./IDepositable.sol";
import "./ISaver.sol";

contract OrionMoney is OwnableUpgradeable, IDepositable, ISaver {
  using Math for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Balance {
    uint256 original_amount;
    uint256 orioned_amount;
  }

  // currency (erc20 stable coin contract address) => user address => balances
  mapping(IERC20 => mapping(address => Balance)) private _balances;

  struct TokenInfo {
    IERC20 proxy_token;
    IERC20 anchored_token;
    IConversionPool conversion_pool;
    IExchangeRateFeeder exchange_rate_feeder;
    StableRateFeeder orion_rate_feeder;
    uint256 ten_pow_decimals;  // 10 ** decimals
  }

  struct WithdrawOperation {
    bytes20 operation_id;
    address user;
    uint256 requested_amount;
    uint256 requested_amount_after_fee;
    uint256 anchored_amount;
    uint256 orioned_amount;
    uint256 updated_original_amount;
  }

  // ERC20 stable coin contract address => anchored token contract address & conversion pool
  mapping(IERC20 => TokenInfo) private _tokens;
  // token => total amount of requested and not finished withdraw amount for all users
  mapping(IERC20 => uint256) private _total_pending_withdraw_amount;
  // token => sum of orioned_amount across all users
  mapping(IERC20 => uint256) private _total_orioned_amount;

  // pending withdraw operations, some first elements could be already processed and deleted (_first_withdraw_operation > 0)
  mapping(IERC20 => WithdrawOperation[]) private _withdraw_operations;
  // first not finished withdraw operations, used during partial processing
  mapping(IERC20 => uint) _first_withdraw_operation;
  // store index (of _withdraw_operations) + 1
  // 0 - means 'no operation'
  mapping(IERC20 => mapping(address => uint32)) private _active_withdraw_operations;

  // current deposit limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _deposit_limit;
  // current withdraw limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _withdraw_limit;

  // default slippage tolerance, 1% = 0.01 stored as 1000;
  uint256 private _default_slippage_tolerance;
  uint256 constant _default_slippage_tolerance_denom = 100_000;

  bool private _atomic_guard;

  modifier criticalSection() {
    require(_atomic_guard == false, "Reentrancy attack detected");
    _atomic_guard = true;
    _;
    _atomic_guard = false;
  }

  // current local deposit limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _local_deposit_limit;
  // current local withdraw limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _local_withdraw_limit;

  // white list of receivers to transfer deposits to
  mapping(IDepositable => uint8) private _white_list;

  // parameters related to shuttle fee
  uint256 private _min_fee; // minimal fee amount
  uint256 private _max_fee; // maximal fee amount
  uint256 private _fee_fraction; // E.g., 0.1% can be stored as _fee_fraction=100 and _fee_fraction_denom=100_000
  uint256 constant _fee_fraction_denom = 100_000;

  event Deposit(address indexed token, address indexed user, uint256 token_amount, uint256 orioned_amount, uint256 anchored_amount, uint256 real_deposited_token_amount);
  event WithdrawInit(address indexed token, address indexed user, bytes20 indexed operation_id,
                     uint256 requested_amount, uint256 requested_amount_after_fee,
                     uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);
  event WithdrawFinalized(address indexed token, address indexed user, bytes20 indexed operation_id,
                          uint256 requested_amount, uint256 requested_amount_after_fee,
                          uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);

  event TransferDeposit(address indexed token, address indexed user, address indexed receiver, uint256 requested_amount,
                        uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);

  event TokenAdded(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint32 decimals);
  event TokenRemoved(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint256 ten_pow_decimals);
  event TokenUpdated(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint32 decimals);

  function initialize(uint256 deposit_limit, uint256 withdraw_limit) public virtual initializer {
    OwnableUpgradeable.__Ownable_init();
    _deposit_limit = deposit_limit;
    _withdraw_limit = withdraw_limit;
    _default_slippage_tolerance = 15_000;  // 15%
    _local_deposit_limit = 1_000;
    _local_withdraw_limit = 1_500;
  }

  function checkToken(IERC20 token) internal view {
    require(_tokens[token].anchored_token != IERC20(0), "Token is not registered");
  }

  function addToken(IERC20 token,
                    IERC20 proxy_token,
                    IERC20 anchored_token,
                    IConversionPool conversion_pool,
                    IExchangeRateFeeder exchange_rate_feeder,
                    StableRateFeeder orion_rate_feeder,
                    uint32 decimals)
  public onlyOwner {
    require(token != IERC20(0), "Zero address provided");
    require(_tokens[token].anchored_token == IERC20(0), "Token already registered");

    _tokens[token].proxy_token = proxy_token;
    _tokens[token].anchored_token = anchored_token;
    _tokens[token].conversion_pool = conversion_pool;
    _tokens[token].exchange_rate_feeder = exchange_rate_feeder;
    _tokens[token].orion_rate_feeder = orion_rate_feeder;
    _tokens[token].ten_pow_decimals = 10 ** uint256(decimals);
    _total_pending_withdraw_amount[token] = 0;
    _total_orioned_amount[token] = 0;

    emit TokenAdded(address(token),
                    address(proxy_token),
                    address(anchored_token),
                    address(conversion_pool),
                    address(exchange_rate_feeder),
                    address(orion_rate_feeder),
                    decimals);
  }

  function updateToken(IERC20 token,
                       IERC20 proxy_token,
                       IERC20 anchored_token,
                       IConversionPool conversion_pool,
                       IExchangeRateFeeder exchange_rate_feeder,
                       StableRateFeeder orion_rate_feeder,
                       uint32 decimals)
  public onlyOwner criticalSection {
    checkToken(token);

    _tokens[token].proxy_token = proxy_token;
    _tokens[token].anchored_token = anchored_token;
    _tokens[token].conversion_pool = conversion_pool;
    _tokens[token].exchange_rate_feeder = exchange_rate_feeder;
    _tokens[token].orion_rate_feeder = orion_rate_feeder;
    _tokens[token].ten_pow_decimals = 10 ** uint256(decimals);

    emit TokenUpdated(address(token),
                      address(proxy_token),
                      address(anchored_token),
                      address(conversion_pool),
                      address(exchange_rate_feeder),
                      address(orion_rate_feeder),
                      decimals);
  }

  function removeToken(IERC20 token) public onlyOwner criticalSection {
    checkToken(token);
    require(_total_pending_withdraw_amount[token] == 0, "There are active withdraw operations");
    require(_total_orioned_amount[token] == 0, "There are deposits in this token");

    emit TokenRemoved(address(token),
                      address(_tokens[token].proxy_token),
                      address(_tokens[token].anchored_token),
                      address(_tokens[token].conversion_pool),
                      address(_tokens[token].exchange_rate_feeder),
                      address(_tokens[token].orion_rate_feeder),
                      _tokens[token].ten_pow_decimals);

    delete _total_pending_withdraw_amount[token];
    delete _total_orioned_amount[token];
    delete _tokens[token];
  }

  function setLocalLimits(uint256 local_deposit_limit, uint256 local_withdraw_limit) public onlyOwner {
    _local_deposit_limit = local_deposit_limit;
    _local_withdraw_limit = local_withdraw_limit;
  }

  function setLimits(uint256 deposit_limit, uint256 withdraw_limit) public onlyOwner {
    _deposit_limit = deposit_limit;
    _withdraw_limit = withdraw_limit;
  }

  function getDepositLimit() public override view returns (uint256) {
    return _deposit_limit;
  }

  function getWithdrawLimit() public override view returns (uint256) {
    return _withdraw_limit;
  }

  function getLocalDepositLimit() public override view returns (uint256) {
    return _local_deposit_limit;
  }

  function getLocalWithdrawLimit() public override view returns (uint256) {
    return _local_withdraw_limit;
  }

  function getLimits() public view returns (uint256 deposit_limit,
                                            uint256 withdraw_limit,
                                            uint256 local_deposit_limit,
                                            uint256 local_withdraw_limit) {
    deposit_limit        = _deposit_limit;
    withdraw_limit       = _withdraw_limit;
    local_deposit_limit  = _local_deposit_limit;
    local_withdraw_limit = _local_withdraw_limit;
  }

  function setDefaultSlippageTolerance(uint256 new_tolerance) public onlyOwner {
    require(new_tolerance >= 0 && new_tolerance <= _default_slippage_tolerance_denom,
            "Value should be in [0 .. 100%] i.e. [0 .. 100_000]");
    _default_slippage_tolerance = new_tolerance;
  }

  function getDefaultSlippageTolerance() public view returns (uint256) {
    return _default_slippage_tolerance;
  }

  function isValidToken(IERC20 token) public view returns (bool) {
    return _tokens[token].anchored_token != IERC20(0);
  }

  function getTokenAnchorAddress(IERC20 token) public view returns (IERC20) {
    return _tokens[token].anchored_token;
  }

  function getTokenInfo(IERC20 token) public view returns (
      IERC20 proxy_token,
      IERC20 anchored_token,
      IConversionPool conversion_pool,
      IExchangeRateFeeder exchange_rate_feeder,
      StableRateFeeder orion_rate_feeder,
      uint256 ten_pow_decimals) {
    checkToken(token);

    proxy_token = _tokens[token].proxy_token;
    anchored_token = _tokens[token].anchored_token;
    conversion_pool = _tokens[token].conversion_pool;
    exchange_rate_feeder = _tokens[token].exchange_rate_feeder;
    orion_rate_feeder = _tokens[token].orion_rate_feeder;
    ten_pow_decimals = _tokens[token].ten_pow_decimals;
  }

  // @action == 1: add @receiver to the white list
  // @action == 0: remove @receiver from the white list
  function addToWhiteList(IDepositable receiver, uint8 action) public onlyOwner {
    require(receiver != IDepositable(0), "Zero address provided");
    _white_list[receiver] = action;
  }

  function balanceOf(IERC20 token, address user) public view override returns (uint256 original_amount,
                                                                      uint256 orioned_amount,
                                                                      uint256 current_amount) {
    checkToken(token);

    Balance memory balance = _balances[token][user];
    original_amount = balance.original_amount;
    orioned_amount = balance.orioned_amount;
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    current_amount = orion_rate_feeder.multiplyByCurrentRate(orioned_amount);
  }

  function convert_atokens_to_tokens(IERC20 token, uint256 atoken_amount) internal view returns (uint256) {
    IExchangeRateFeeder feeder = _tokens[token].exchange_rate_feeder;
    uint256 pER = feeder.exchangeRateOf(address(token), true);
    return atoken_amount.mul(pER).div(1e18).mul(_tokens[token].ten_pow_decimals).div(1e18);
  }

  function convert_tokens_to_atokens(IERC20 token, uint256 token_amount) internal view returns (uint256) {
    IExchangeRateFeeder feeder = _tokens[token].exchange_rate_feeder;
    uint256 pER = feeder.exchangeRateOf(address(token), true);
    return token_amount.mul(1e18).div(pER).mul(1e18).div(_tokens[token].ten_pow_decimals);
  }

  function convert_tokens_to_orioned_amount(IERC20 token, uint256 requested_amount) internal view returns (uint256) {
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    return requested_amount.mul(1e18).div(orion_rate_feeder.multiplyByCurrentRate(1e18));
  }

  function convert_orioned_amount_to_tokens(IERC20 token, uint256 orioned_amount) internal view returns (uint256) {
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    return orion_rate_feeder.multiplyByCurrentRate(orioned_amount);
  }

  /*

  The following functions help to manage 'unbonded' token and aToken ammounts.
  'Unbonded' token amount is the amount in excess of tokens required to cover users deposits.

  Let's say users deposited 10,000 USDT in total, and that equals to 9,500 aUSDT at current
  USDT/aUSDT exchange rate. If contract has 9700 aUSDT, then 200 aUSDT is the amount of 'unbonded'
  tokens. In other words, if all users decide to withdraw their deposits, we would need 9,500
  aUST to cover it, and 200 aUSDT will belong to Orion Money project.

  */


  /*

  Calculates amount of unbonded aTokens

  */
  function getFreeAnchoredAmount(IERC20 token) public view returns (int256) {
    checkToken(token);

    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    uint256 total_deposits_amount = orion_rate_feeder.multiplyByCurrentRate(_total_orioned_amount[token]);

    IERC20 atoken = _tokens[token].anchored_token;
    uint256 total_atokens = atoken.balanceOf(address(this));
    return int256(total_atokens) - int256(convert_tokens_to_atokens(token, total_deposits_amount));
  }

  /*

  Withdraws aTokens limited by unbonded aTokens amount

  */
  function takeAnchoredProfit(IERC20 token, address receiver, uint256 amount) public onlyOwner criticalSection {
    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    require(int256(amount) <= free_anchored_amount, "Amount exceeds the amount of unbonded atokens");
    _tokens[token].anchored_token.safeTransfer(receiver, amount);
  }

  /*

  Calculates amount of unbonded tokens that can be deposited to EthAnchor or taken away

  */
  function getDepositableAmount(IERC20 token) public view returns (int256) {
    checkToken(token);

    uint256 contract_balance = token.balanceOf(address(this));
    return int256(contract_balance) - int256(_total_pending_withdraw_amount[token]);
  }

  /*

  Withdraws tokens limited by unbounded tokens amount

  */
  function takeProfit(IERC20 token, address receiver, uint256 amount) public onlyOwner criticalSection {
    uint256 contract_balance = token.balanceOf(address(this));
    require(contract_balance >= _total_pending_withdraw_amount[token] + amount, "Amount exceeds the amount of unbonded tokens");
    token.safeTransfer(receiver, amount);
  }

  /*

  Similar to takeProfit. Instead of withdrawing unbonded tokens, deposits amount to Anchorprotocol.
  Obtained aTokens could be later withdrawn using takeAnchorProfit, or could stay on contract to server
  depositLocal calls.

  */
  function depositFreeFunds(IERC20 token, uint256 amount) public onlyOwner criticalSection {
    require(token.balanceOf(address(this)) >= _total_pending_withdraw_amount[token] + amount,
      "Amount exceeds the amount of unbonded tokens");

    token.safeApprove(address(_tokens[token].conversion_pool), amount);

    _tokens[token].conversion_pool.deposit(
      amount,
      amount.sub(amount.mul(_default_slippage_tolerance).div(_default_slippage_tolerance_denom))
    );
  }

  /*

  Similar to takeAnchoredProfit. Instead of withdrawing unbonded aTokens, redeems if from Anchorprotocol.
  Redeemed tokens could be later withdrawn using takeProfit, or could stay on contract to serve
  withdrawLocal calls.

  */
  function withdrawFreeFunds(IERC20 token, uint256 anchored_amount) public onlyOwner criticalSection {
    require(getFreeAnchoredAmount(token) >= int256(anchored_amount), "Amount exceeds the amount of unbonded atokens");

    _tokens[token].anchored_token.safeApprove(address(_tokens[token].conversion_pool), anchored_amount);
    _tokens[token].conversion_pool.redeem(anchored_amount);
  }

  /*

  Checks if contract has enough unbounded aTokens for specified amount of tokens

  */
  function canDepositLocal(IERC20 token, uint256 amount) public override view returns(bool) {
    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    uint256 atokens_to_deposit = convert_tokens_to_atokens(token, amount);
    return int256(atokens_to_deposit) <= free_anchored_amount;
  }

  /*

  Local deposit. In contrast to regular deposit function funds are not sent to Anchorprotocol. Instead we
  check if we have enough unbonded aTokens on contract, and update balances accordingly.

  For smaller investors this helps to signinficanlty save on gas fees.

  */
  function depositLocal(IERC20 token, uint256 amount) public override criticalSection {
    require(_active_withdraw_operations[token][msg.sender] == 0, "Withdraw operation pending");
    require(amount.div(_tokens[token].ten_pow_decimals) <= _local_deposit_limit, "Amount exceeds local deposit limit");
    require(amount > 0, "Amount should be greater than zero");

    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    uint256 atokens_to_deposit = convert_tokens_to_atokens(token, amount);
    require(int256(atokens_to_deposit) <= free_anchored_amount, "Not enough free atokens");

    uint256 token_balance_before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), amount);

    require(token.balanceOf(address(this)) - token_balance_before == amount,
      "ERC20 token has not transferred the same amount as requested");

    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, amount);

    _balances[token][msg.sender].original_amount += amount;
    _balances[token][msg.sender].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), msg.sender, amount, deposited_orioned, atokens_to_deposit, amount);
  }

  function deposit(IERC20 token, uint256 amount, uint256 min_amount) public criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "Withdraw operation pending");

    require(amount.div(_tokens[token].ten_pow_decimals) <= _deposit_limit, "Amount exceeds deposit limit");
    require(amount > 0, "Amount should be > 0");

    IERC20 atoken = _tokens[token].anchored_token;

    uint256 token_balance_before = token.balanceOf(address(this));
    uint256 atoken_balance_before = atoken.balanceOf(address(this));

    token.safeTransferFrom(msg.sender, address(this), amount);

    require(token.balanceOf(address(this)) - token_balance_before == amount,
      "ERC20 token has not transferred the same amount as requested");

    IConversionPool conversion_pool = _tokens[token].conversion_pool;
    token.safeApprove(address(conversion_pool), amount);
    conversion_pool.deposit(amount, min_amount);

    uint256 atoken_balance_after = atoken.balanceOf(address(this));

    uint256 atokens_deposited = atoken_balance_after.sub(atoken_balance_before);
    uint256 real_deposited_token_amount = convert_atokens_to_tokens(token, atokens_deposited);
    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, real_deposited_token_amount);

    _balances[token][msg.sender].original_amount += real_deposited_token_amount;
    _balances[token][msg.sender].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), msg.sender, amount, deposited_orioned, atokens_deposited, real_deposited_token_amount);
  }

  /*

  There are cases, when we want to accept deposits in aTokens directly. For example, if user participated in
  Private Farming, but decided to continue holding funds with Orion Saver we will just transfer his/her aTokens from
  Private Farming contract to Orion Saver

  */
  function depositAnchored(IERC20 token, address depositor, uint256 anchored_amount) public override criticalSection  {
    require(depositor != address(0), "Wrong depositor address");
    checkToken(token);
    require(_active_withdraw_operations[token][depositor] == 0, "Withdraw operation pending");
    require(anchored_amount > 0, "Amount should be > 0");

    uint256 stable_coin_amount = convert_atokens_to_tokens(token, anchored_amount);
    require(stable_coin_amount.div(_tokens[token].ten_pow_decimals) <= _deposit_limit, "Amount exceeds deposit limit");

    IERC20 atoken = _tokens[token].anchored_token;

    uint256 atoken_balance_before = atoken.balanceOf(address(this));
    /* Transferring funds from msg.sender (contract) */
    atoken.safeTransferFrom(msg.sender, address(this), anchored_amount);
    require(atoken.balanceOf(address(this)) - atoken_balance_before == anchored_amount,
      "ERC20 token has not transferred the same amount as requested");

    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, stable_coin_amount);
    /* Depositing funds in favour of depositor */
    _balances[token][depositor].original_amount += stable_coin_amount;
    _balances[token][depositor].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), depositor, stable_coin_amount, deposited_orioned, anchored_amount, stable_coin_amount);
  }

  // with default slippage tolerance
  function deposit(IERC20 token, uint256 amount) public override {
    deposit(token, amount, amount.sub(amount.mul(_default_slippage_tolerance).div(_default_slippage_tolerance_denom)));
  }

  /*

  Checks if contract has enough unbounded tokens to withdraw funds right away

  */
  function canWithdrawLocal(IERC20 token, uint256 amount) public override view returns(bool) {
    uint256 current_balance = token.balanceOf(address(this));
    return current_balance >= _total_pending_withdraw_amount[token] + amount;
  }

  /*

  Local deposit. In contrast to regular deposit function funds are not withdrawn from Anchorprotocol.
  Instead we check if we have enough unbonded tokens on contract, transfer funds to user, and
  update balances accordingly

  For smaller investors this helps to signinficanlty save on gas fees.

  */
  function withdrawLocal(IERC20 token, uint256 requested_amount) public override criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0,
      "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _local_withdraw_limit,
      "Amount exceeds local withdraw limit");

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);
    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 current_balance = token.balanceOf(address(this));
    require(current_balance >= _total_pending_withdraw_amount[token] + requested_amount, "Insufficient unbonded tokens");

    token.safeTransfer(msg.sender, requested_amount);

    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);
    _balances[token][msg.sender].original_amount = updated_original_amount;

    _balances[token][msg.sender].orioned_amount = _balances[token][msg.sender].orioned_amount
                                                      .sub(requested_orioned_amount);

    _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);

    bytes20 operation_id = bytes20(keccak256(abi.encodePacked(block.number, token, msg.sender)));

    /*
      to support same interface we simply emit two events one after another.
      This way event listener (backend) doesn't need to handle local deposits differently
      from regular deposits
    */
    emit WithdrawInit(address(token), msg.sender, operation_id,
                      requested_amount, requested_amount,
                      requested_anchored_amount, requested_orioned_amount, updated_original_amount);

    emit WithdrawFinalized(address(token), msg.sender, operation_id,
                          requested_amount, requested_amount,
                          requested_anchored_amount, requested_orioned_amount, updated_original_amount);
  }

  // @min_fee and @max_fee should be in whole units (without decimal zeroes), i.e. 1 means 1$.
  function setWithdrawFee(uint256 min_fee,
                          uint256 max_fee,
                          uint256 fee_fraction) public onlyOwner {
    require(min_fee <= max_fee, "min_fee is greater than max_fee");
    require(min_fee <= 100_000, "min_fee is too large");
    _min_fee = min_fee;
    _max_fee = max_fee;
    _fee_fraction = fee_fraction;
  }

  function get_withdraw_fee(IERC20 token, uint256 amount) public view returns(uint256) {
    // clamp(amount * fee_fraction, min_fee, max_fee)
    return amount
      .mul(_fee_fraction).div(_fee_fraction_denom)
      .max(_min_fee * _tokens[token].ten_pow_decimals)
      .min(_max_fee * _tokens[token].ten_pow_decimals);
  }

  function withdraw(IERC20 token, uint256 requested_amount) public override criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _withdraw_limit, "Amount exceeds withdraw limit");

    IERC20 atoken = _tokens[token].anchored_token;

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);
    uint256 requested_amount_after_fee = requested_amount.sub(get_withdraw_fee(token, requested_amount));

    // do redeem
    {
      uint256 atoken_balance_before = atoken.balanceOf(address(this));
      require(atoken_balance_before >= requested_anchored_amount, "Insufficient funds on contract anchored balance");

      atoken.safeApprove(address(_tokens[token].conversion_pool), requested_anchored_amount);
      _tokens[token].conversion_pool.redeem(requested_anchored_amount);

      require(atoken_balance_before - atoken.balanceOf(address(this)) == requested_anchored_amount,
        "Redeem has not transferred full approved amount");

      _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);
      _total_pending_withdraw_amount[token] = _total_pending_withdraw_amount[token].add(requested_amount_after_fee);
    }

    // require(current_amount >= requested_amount) already checked
    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);

    bytes20 operation_id = bytes20(keccak256(abi.encodePacked(block.number, token, msg.sender)));

    _withdraw_operations[token].push(WithdrawOperation({
      operation_id: operation_id,
      user: msg.sender,
      requested_amount: requested_amount,
      requested_amount_after_fee: requested_amount_after_fee,
      anchored_amount: requested_anchored_amount,
      orioned_amount: requested_orioned_amount,
      updated_original_amount: updated_original_amount}));

    _active_withdraw_operations[token][msg.sender] = uint32(_withdraw_operations[token].length);

    emit WithdrawInit(address(token), msg.sender, operation_id,
                      requested_amount, requested_amount_after_fee,
                      requested_anchored_amount, requested_orioned_amount, updated_original_amount);
  }

  /*

  There are cases when users might want to transfer aTokens between Orion Money contracts.
  For example, if user holds funds with Orion Saver, but wants to participate in Private Farming event,
  this function will allow to transfer aTokens to PrivateFarming contract without withdrawing and then
  depositing back (helps to save on fees)

  */
  function transferDeposit(IERC20 token, IDepositable receiver, uint256 requested_amount) public criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _withdraw_limit, "Amount exceeds withdraw limit");
    require(_white_list[receiver] == 1, "Receiver is not in the white list");

    IERC20 atoken = _tokens[token].anchored_token;

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);

    uint256 atoken_balance_before = atoken.balanceOf(address(this));
    require(atoken_balance_before >= requested_anchored_amount, "Insufficient funds on contract anchored balance");

    atoken.safeApprove(address(receiver), requested_anchored_amount);
    receiver.depositAnchored(token, msg.sender, requested_anchored_amount);

    require(atoken_balance_before - atoken.balanceOf(address(this)) == requested_anchored_amount,
      "Deposit Receiver did not transfer approved tokens");

    _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);

    // require(current_amount >= requested_amount) already checked
    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);

    _balances[token][msg.sender].original_amount = updated_original_amount;
    _balances[token][msg.sender].orioned_amount = _balances[token][msg.sender].orioned_amount.sub(requested_orioned_amount);

    emit TransferDeposit(address(token), msg.sender, address(receiver),
      requested_amount, requested_anchored_amount,
      requested_orioned_amount, updated_original_amount);
  }

  function finalizeWithdrawUpToUser(IERC20 token, address stop_address) public criticalSection {
    checkToken(token);
    require(_withdraw_operations[token].length > _first_withdraw_operation[token], "No active withdraw operations");

    uint256 current_balance = token.balanceOf(address(this));
    uint i = _first_withdraw_operation[token];
    for (; i < _withdraw_operations[token].length; ++i) {
      WithdrawOperation memory op = _withdraw_operations[token][i];

      if (current_balance >= op.requested_amount_after_fee) {
        _balances[token][op.user].original_amount = op.updated_original_amount;
        _balances[token][op.user].orioned_amount = _balances[token][op.user].orioned_amount.sub(op.orioned_amount);

        token.safeTransfer(op.user, op.requested_amount_after_fee);

        _total_pending_withdraw_amount[token] = _total_pending_withdraw_amount[token].sub(op.requested_amount_after_fee);

        delete _active_withdraw_operations[token][op.user];
        delete _withdraw_operations[token][i];

        emit WithdrawFinalized(address(token), op.user, op.operation_id,
                               op.requested_amount, op.requested_amount_after_fee,
                               op.anchored_amount, op.orioned_amount, op.updated_original_amount);

        current_balance -= op.requested_amount_after_fee;
        if (op.user == stop_address) {
          ++i;
          break;
        }
      } else {
        require(i != _first_withdraw_operation[token], "Not enough funds on contract");
        break;
      }
    }

    // fully processed
    if (i < _withdraw_operations[token].length) {
      _first_withdraw_operation[token] = i;
    } else {
      delete _withdraw_operations[token];
      if (_first_withdraw_operation[token] != 0) _first_withdraw_operation[token] = 0;
    }
  }

  function finalizeWithdraw(IERC20 token) public {
    return finalizeWithdrawUpToUser(token, address(0));
  }

  function getActiveWithdrawOperationsCount(IERC20 token) public view returns (uint) {
    return _withdraw_operations[token].length - _first_withdraw_operation[token];
  }

  // 2 - can process 2 operation
  // 1 - can process 1 operation
  // 0 - can't process even the first operation
  // -1 - there is no any active operation to process
  function getWithdrawOperationsAbleToProcess(IERC20 token) public view returns (int) {
    checkToken(token);

    if (_first_withdraw_operation[token] >= _withdraw_operations[token].length) {
      return -1;
    }

    uint256 current_balance = token.balanceOf(address(this));
    uint i = _first_withdraw_operation[token];
    for (; i < _withdraw_operations[token].length; ++i) {
      if (current_balance < _withdraw_operations[token][i].requested_amount_after_fee) {
        break;
      }
      current_balance -= _withdraw_operations[token][i].requested_amount_after_fee;
    }
    return int(i - _first_withdraw_operation[token]);
  }

  function getWithdrawOperationByIndex(IERC20 token, uint idx) public view
  returns (bytes20 operation_id,
           address user,
           uint256 requested_amount,
           uint256 requested_amount_after_fee,
           uint256 anchored_amount,
           uint256 orioned_amount,
           uint256 updated_original_amount) {
    checkToken(token);
    require(idx + _first_withdraw_operation[token] < _withdraw_operations[token].length, "Index out of bounds");
    WithdrawOperation memory op = _withdraw_operations[token][idx + _first_withdraw_operation[token]];
    return (op.operation_id, op.user, op.requested_amount, op.requested_amount_after_fee,
            op.anchored_amount, op.orioned_amount, op.updated_original_amount);
  }

  function getActiveWithdrawOperation(IERC20 for_token, address for_user) public view
  returns (bytes20 operation_id,
           address user,
           uint256 requested_amount,
           uint256 requested_amount_after_fee,
           uint256 anchored_amount,
           uint256 orioned_amount,
           uint256 updated_original_amount) {
    checkToken(for_token);
    uint32 index_plus_1 = _active_withdraw_operations[for_token][for_user];
    require(index_plus_1 > _first_withdraw_operation[for_token] && index_plus_1 <= _withdraw_operations[for_token].length,
           "Active withdraw operation for this user and token not found");
    return getWithdrawOperationByIndex(for_token, index_plus_1 - 1);
  }

  function hasActiveWithdrawOperation(IERC20 token, address user) public view returns (bool) {
    checkToken(token);
    uint32 index_p1 = _active_withdraw_operations[token][user];
    return index_p1 > _first_withdraw_operation[token] && index_p1 <= _withdraw_operations[token].length;
  }

  function getTotalPendingWithdrawAmount(IERC20 token) public view returns (uint256) {
    checkToken(token);
    return _total_pending_withdraw_amount[token];
  }
}
