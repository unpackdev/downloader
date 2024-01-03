// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./BigDiv.sol";
import "./Sqrt.sol";
import "./Take.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./TokenTimelock.sol";


/**
 * @title Decentralized Autonomous Trust
 * This contract is a modified version of the implementation provided by Fairmint for a
 * Decentralized Autonomous Trust as described in the continuous
 * organization whitepaper (https://github.com/c-org/whitepaper) and
 * specified here: https://github.com/fairmint/c-org/wiki.
 * Code from : https://github.com/Fairmint/c-org/blob/dfd3129f9bce8717406aba54d1f1888d8e253dbb/contracts/DecentralizedAutonomousTrust.sol
 * Changes Added: https://github.com/Fairmint/c-org/commit/60bb63b9112a82996f275a75a87c28b1d73e3f11
 *
 * Use at your own risk. 
 */
contract DecentralizedAutonomousTrust
  is Take
{
  using SafeMath for uint;
  using Sqrt for uint;
  using SafeERC20 for IERC20;

  /**
   * Events
   */

  event Buy(
    address indexed _from,
    address indexed _to,
    uint256 _currencyValue,
    uint256 _fairValue
  );
  event Close();
  event StateChange(
    uint256 _previousState,
    uint256 _newState
  );
  event UpdateConfig(
    address indexed _beneficiary,
    address indexed _control,
    address _uniswapRouterAddress,
    address _uniswapFactoryAddress,
    uint256 _minInvestment,
    uint256 _openUntilAtLeast
  );
  // Constants

  //  The default state
  uint256 private constant STATE_INIT = 0;

  //  The state after initGoal has been reached
  uint256 private constant STATE_RUN = 1;

  //  The state after closed by the `beneficiary` account from STATE_RUN
  uint256 private constant STATE_CLOSE = 2;

  //  The state after closed by the `beneficiary` account from STATE_INIT
  uint256 private constant STATE_CANCEL = 3;

  //  When multiplying 2 terms, the max value is 2^128-1
  uint256 private constant MAX_BEFORE_SQUARE = 2**128 - 1;

  //  The denominator component for values specified in basis points.
  uint256 private constant BASIS_POINTS_DEN = 10000;

  // The max `totalSupply`
  // @dev This limit ensures that the DAT's formulas do not overflow (<MAX_BEFORE_SQUARE/2)
  uint256 private constant MAX_SUPPLY = 10 ** 38;

  /**
   * Data for DAT business logic
   */

  /// @notice The address of the beneficiary organization which receives the investments.
  /// Points to the wallet of the organization.
  address payable public beneficiary;

  /// @notice The buy slope of the bonding curve.
  /// Does not affect the financial model, only the granularity of TAKE.
  /// @dev This is the numerator component of the fractional value.
  uint256 public buySlopeNum;

  /// @notice The buy slope of the bonding curve.
  /// Does not affect the financial model, only the granularity of TAKE.
  /// @dev This is the denominator component of the fractional value.
  uint256 public buySlopeDen;

  /// @notice The address from which the updatable variables can be updated
  address public control;

  /// @notice The address of the token used as reserve in the bonding curve
  /// (e.g. the DAI contract). Use ETH if 0.
  IERC20 public currency;

  /// @notice The initial fundraising goal (expressed in TAKE) to start the c-org.
  /// `0` means that there is no initial fundraising and the c-org immediately moves to run state.
  uint256 public initGoal;

  uint256 public initReserve;

  /// @notice The bonding curve fundraising goal.
  uint256 public bcGoal;

  /// @notice The bonding curve fundraising final result.
  uint256 public bcTakeReleased;

  /// @notice The investment reserve of the c-org. Defines the percentage of the value invested that is
  /// automatically funneled and held into the buyback_reserve expressed in basis points.
  uint256 public investmentReserveBasisPoints;

  /// @notice The earliest date/time (in seconds) that the DAT may enter the `CLOSE` state, ensuring
  /// that if the DAT reaches the `RUN` state it will remain running for at least this period of time.
  /// @dev This value may be increased anytime by the control account
  uint256 public openUntilAtLeast;

  /// @notice The minimum amount of `currency` investment accepted.
  uint256 public minInvestment;

  /// @notice The current state of the contract.
  /// @dev See the constants above for possible state values.
  uint256 public state;

  string public constant version = "2";
  // --- EIP712 niceties ---
  // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
  //  mapping (address => uint) public nonces;
  bytes32 public DOMAIN_SEPARATOR;
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

  address public  uniswapFactoryAddress;
  address public  uniswapRouterAddress;
  IUniswapV2Router02 private uniswapRouter;
  IUniswapV2Factory private uniswapFactory;
  address internal constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
  uint96 private constant uniswapBurnRate = 1000;
  address public uniswapPairAddress = 0x0000000000000000000000000000000000000000;
  address public uniswapTokenTimelockAddress = 0x0000000000000000000000000000000000000000;
  address public takeTimelockAddress = 0x0000000000000000000000000000000000000000;

  // Team Revenue in percent
  uint256 private constant teamRevenueBasisPoints = 3000;

  //
  bool public bcFlowAllowed = false;

  /// Pay

  /// @notice Pay the organization on-chain without minting any tokens.
  /// @dev This allows you to add funds directly to the buybackReserve.
  function pay() external payable
  {
    require(address(currency) == address(0), "ONLY_FOR_CURRENCY_ETH");
  }

  function handleBC(
    bool withdrawOnError
  ) external
  {
    require(state == STATE_CLOSE, "ONLY_AFTER_CLOSE");
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

    uint256 reserve = address(this).balance;
    require(reserve > 0, "MUST_BUY_AT_LEAST_1");

    uint256 teamReserve = reserve.mul(teamRevenueBasisPoints);
    teamReserve /= BASIS_POINTS_DEN;
    uint256 uniswapPoolEthAmount  = reserve.sub(teamReserve);

    uint256 uniswapPoolTakeAmount = uniswapPoolEthAmount.mul(buySlopeDen);
    uniswapPoolTakeAmount = uniswapPoolTakeAmount.div(bcTakeReleased);
    uniswapPoolTakeAmount = uniswapPoolTakeAmount.div(buySlopeNum);

    super._allowTokenTransfer();
    super._approve(address(this), uniswapRouterAddress, uint(-1));
    try uniswapRouter.addLiquidityETH{
    value: uniswapPoolEthAmount
    }(
      address(this),
      uniswapPoolTakeAmount,
      uniswapPoolTakeAmount,
      uniswapPoolEthAmount,
      address(this),
      block.timestamp + 15
    ) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
      Address.sendValue(beneficiary, address(this).balance);

      uniswapPairAddress = uniswapFactory.getPair(uniswapRouter.WETH(), address(this));
      super._setBurnConfig(uniswapBurnRate, NULL_ADDRESS);
      super._addBurnSaleAddress(uniswapPairAddress);
      super._setApproveConfig(NULL_ADDRESS);

      lockTakeTokens();
    } catch {
      if (withdrawOnError) {
        Address.sendValue(beneficiary, address(this).balance);
        uint96 amount = safe96(this.balanceOf(address(this)), "DAT:: amount exceeds 96 bits");
        super._transferTokens(address(this), beneficiary, amount);
      }
    }

  }

  function lockUniswapTokens() external {
    require(state == STATE_CLOSE, "ONLY_AFTER_CLOSE");
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

    IERC20 uniswapPair = IERC20(uniswapPairAddress);

    TokenTimelock uniswapTokenTimelock = new TokenTimelock(uniswapPair, beneficiary, block.timestamp + 31 days);
    uniswapTokenTimelockAddress = address(uniswapTokenTimelock);

    uniswapPair.transfer(uniswapTokenTimelockAddress, uniswapPair.balanceOf(address(this)) );
  }

  // --- Approve by signature ---
  // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external
  {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(PERMIT_TYPEHASH,
          holder,
          spender,
          nonce,
          expiry,
          allowed
          )
        )
      )
    );

    require(holder != address(0), "DAT/invalid-address-0");
    require(holder == ecrecover(digest, v, r, s), "DAT/invalid-permit");
    require(expiry == 0 || now <= expiry, "DAT/permit-expired");
    require(nonce == nonces[holder]++, "DAT/invalid-nonce");
    uint256 wad = allowed ? uint(-1) : 0;
    super._approve(holder, spender, wad);
  }

  /**
   * Config / Control
   */

  /// @notice Called once after deploy to set the initial configuration.
  /// None of the values provided here may change once initially set.
  /// @dev using the init pattern in order to support zos upgrades
  function initialize(
    address _currencyAddress,
    uint256 _initGoal,
    uint256 _bcGoal,
    uint256 _buySlopeNum,
    uint256 _buySlopeDen,
    uint256 _investmentReserveBasisPoints
  ) public
  {
    require(control == address(0), "ALREADY_INITIALIZED");

    initReserve = 0;

    // Set initGoal, which in turn defines the initial state
    if(_initGoal == 0)
    {
      emit StateChange(state, STATE_RUN);
      state = STATE_RUN;
    }
    else
    {
      // Math: If this value got too large, the DAT would overflow on sell
      require(_initGoal < MAX_SUPPLY, "EXCESSIVE_GOAL");
      initGoal = _initGoal;
    }

    require(_bcGoal > 0, "INVALID_BC_GOAL");
    bcGoal = _bcGoal;

    bcTakeReleased = 0;

    require(_buySlopeNum > 0, "INVALID_SLOPE_NUM");
    require(_buySlopeDen > 0, "INVALID_SLOPE_DEN");
    require(_buySlopeNum < MAX_BEFORE_SQUARE, "EXCESSIVE_SLOPE_NUM");
    require(_buySlopeDen < MAX_BEFORE_SQUARE, "EXCESSIVE_SLOPE_DEN");
    buySlopeNum = _buySlopeNum;
    buySlopeDen = _buySlopeDen;
    // 100% or less
    require(_investmentReserveBasisPoints <= BASIS_POINTS_DEN, "INVALID_RESERVE");
    investmentReserveBasisPoints = _investmentReserveBasisPoints;

    // Set default values (which may be updated using `updateConfig`)
    minInvestment = 1 ether;
    beneficiary = msg.sender;
    control = msg.sender;

    // Save currency
    currency = IERC20(_currencyAddress);

    // Initialize permit
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        _getChainId(),
        address(this)
      )
    );
  }

  function updateConfig(
    address payable _beneficiary,
    address _control,
    address _uniswapRouterAddress,
    address _uniswapFactoryAddress,
    uint256 _minInvestment,
    uint256 _openUntilAtLeast
  ) public
  {
    // This require(also confirms that initialize has been called.
    require(msg.sender == control, "CONTROL_ONLY");

    require(_control != address(0), "INVALID_ADDRESS");
    control = _control;

    require(_uniswapRouterAddress != address(0), "INVALID_ADDRESS");
    uniswapRouterAddress = _uniswapRouterAddress;

    require(_uniswapFactoryAddress != address(0), "INVALID_ADDRESS");
    uniswapFactoryAddress = _uniswapFactoryAddress;

    uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);

    require(_minInvestment > 0, "INVALID_MIN_INVESTMENT");
    minInvestment = _minInvestment;

    require(_openUntilAtLeast >= openUntilAtLeast, "OPEN_UNTIL_MAY_NOT_BE_REDUCED");
    openUntilAtLeast = _openUntilAtLeast;

    if(beneficiary != _beneficiary)
    {
      require(_beneficiary != address(0), "INVALID_ADDRESS");
      uint256 tokens = balances[beneficiary];
      if(tokens > 0)
      {
        _transfer(beneficiary, _beneficiary, tokens);
      }
      beneficiary = _beneficiary;
    }

    emit UpdateConfig(
      _beneficiary,
      _control,
      _uniswapRouterAddress,
      _uniswapFactoryAddress,
      _minInvestment,
      _openUntilAtLeast
    );
  }

  function allowBcFlow() public {
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");
    bcFlowAllowed = true;
  }

  /**
   * Functions for our business logic
   */


  // Buy

  /// @notice Calculate how many TAKE tokens you would buy with the given amount of currency if `buy` was called now.
  /// @param _currencyValue How much currency to spend in order to buy TAKE.
  function estimateBuyValue(
    uint256 _currencyValue
  ) public view
    returns (uint)
  {
    if(_currencyValue < minInvestment)
    {
      return 0;
    }

    /// Calculate the tokenValue for this investment
    uint256 tokenValue;
    if(state == STATE_RUN)
    {
      uint256 supply = bcTakeReleased;
      // Math: worst case
      // MAX * 2 * MAX_BEFORE_SQUARE
      // / MAX_BEFORE_SQUARE
      tokenValue = BigDiv.bigDiv2x1(
        _currencyValue,
        2 * buySlopeDen,
        buySlopeNum
      );

      // Math: worst case MAX + (MAX_BEFORE_SQUARE * MAX_BEFORE_SQUARE)
      tokenValue = tokenValue.add(supply * supply);
      tokenValue = tokenValue.sqrt();

      // Math: small chance of underflow due to possible rounding in sqrt
      tokenValue = tokenValue.sub(supply);
    }
    else
    {
      // invalid state
      return 0;
    }

    return tokenValue;
  }

  function estimateBuyTokensValue (
    uint256 _tokenValue
  ) public view
    returns (uint)
  {
    /// Calculate the investment to buy _tokenValue
    uint256 currencyValue;
    if(state == STATE_RUN) {
      uint256 supply = bcTakeReleased;

      uint256 tokenValue = _tokenValue.add(supply);

      tokenValue = tokenValue.mul(tokenValue);
      tokenValue = tokenValue.sub(supply * supply);

      currencyValue = BigDiv.bigDiv2x1(
        tokenValue,
        buySlopeNum,
        2 * buySlopeDen
      );
    }
    else
    {
      // invalid state
      return 0;
    }

  return currencyValue;
  }

  /// @notice Purchase TAKE tokens with the given amount of currency.
  /// @param _to The account to receive the TAKE tokens from this purchase.
  /// @param _currencyValue How much currency to spend in order to buy TAKE.
  /// @param _minTokensBought Buy at least this many TAKE tokens or the transaction reverts.
  /// @dev _minTokensBought is necessary as the price will change if some elses transaction mines after
  /// yours was submitted.
  function buy(
    address _to,
    uint256 _currencyValue,
    uint256 _minTokensBought
  ) public payable
  {
    require(bcFlowAllowed, "TOKEN_SALE_NOT_STARTED");
    require(_to != address(0), "INVALID_ADDRESS");
    require(_minTokensBought > 0, "MUST_BUY_AT_LEAST_1");
    require(bcGoal >= bcTakeReleased, "BC_GOAL_REACHED");

    bool closeAfterBuy = false;

    // Calculate the tokenValue for this investment
    uint256 tokenValue = estimateBuyValue(_currencyValue);
    if (bcTakeReleased.add(tokenValue) >= bcGoal) {
      closeAfterBuy = true;
      tokenValue = bcGoal.sub(bcTakeReleased);
      _currencyValue = estimateBuyTokensValue(tokenValue);
    }

    require(tokenValue >= _minTokensBought, "PRICE_SLIPPAGE");

    emit Buy(msg.sender, _to, _currencyValue, tokenValue);

    _collectInvestment(_currencyValue, msg.value, true);
    super._transferTokens(address(this), _to, safe96(tokenValue, "DAT:: amount exceeds 96 bits"));

    bcTakeReleased = bcTakeReleased.add(tokenValue);

    if(state == STATE_RUN && closeAfterBuy) {
      _close();
    }
  }
  
  /// Close

  /// @notice Called by the beneficiary account to STATE_CLOSE or STATE_CANCEL the c-org.
  function close() public
  {
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");
    _close();
  }

  /**
 * Functions required by the ERC-20 token standard
 */

  /// @dev Moves tokens from one account to another if authorized.
  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal
  {
    require(state != STATE_INIT || _from == beneficiary, "ONLY_BENEFICIARY_DURING_INIT");
    uint96 amount = safe96(_amount, "DAT::transfer: amount exceeds 96 bits");
    super._transferTokens(_from, _to, amount);
  }

  function _close() private
  {
    if(state == STATE_INIT)
    {
      // Allow the org to cancel anytime if the initGoal was not reached.
      emit StateChange(state, STATE_CANCEL);
      state = STATE_CANCEL;
    }
    else if(state == STATE_RUN)
    {
      require(openUntilAtLeast <= block.timestamp, "TOO_EARLY");

      emit StateChange(state, STATE_CLOSE);
      state = STATE_CLOSE;
    }
    else
    {
      revert("INVALID_STATE");
    }

    emit Close();
  }


  /**
   * Transaction Helpers
   */

  /// @notice Confirms the transfer of `_quantityToInvest` currency to the contract.
  function _collectInvestment(
    uint256 _quantityToInvest,
    uint256 _msgValue,
    bool _refundRemainder
  ) private
  {
    if(address(currency) == address(0))
    {
      // currency is ETH
      if(_refundRemainder)
      {
        // Math: if _msgValue was not sufficient then revert
        uint256 refund = _msgValue.sub(_quantityToInvest);
        if(refund > 0)
        {
          Address.sendValue(msg.sender, refund);
        }
      }
      else
      {
        require(_quantityToInvest == _msgValue, "INCORRECT_MSG_VALUE");
      }
    }
    else
    {
      // currency is ERC20
      require(_msgValue == 0, "DO_NOT_SEND_ETH");

      currency.safeTransferFrom(msg.sender, address(this), _quantityToInvest);
    }
  }

  /// @dev Send `_amount` currency from the contract to the `_to` account.
  function _transferCurrency(
    address payable _to,
    uint256 _amount
  ) private
  {
    if(_amount > 0)
    {
      if(address(currency) == address(0))
      {
        Address.sendValue(_to, _amount);
      }
      else
      {
        currency.safeTransfer(_to, _amount);
      }
    }
  }

  function _getChainId(
  ) private pure
  returns (uint256 id)
  {
    // solium-disable-next-line
    assembly
    {
      id := chainid()
    }
  }

  function lockTakeTokens() private {
    require(state == STATE_CLOSE, "ONLY_AFTER_CLOSE");
    require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

    TokenTimelock takeTokenTimelock = new TokenTimelock(IERC20(address(this)), beneficiary, block.timestamp + 31 days);
    takeTimelockAddress = address(takeTokenTimelock);

    this.transfer(takeTimelockAddress, this.balanceOf(address(this)) );
  }
}
