// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./OwnableUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./FixedPoint.sol";
import "./RegistryInterface.sol";
import "./ReserveInterface.sol";
import "./TokenListenerInterface.sol";
import "./TokenListenerLibrary.sol";
import "./ControlledToken.sol";
import "./TokenControllerInterface.sol";
import "./PrizePoolInterface.sol";

abstract contract PrizePool is PrizePoolInterface, OwnableUpgradeable, ReentrancyGuardUpgradeable, TokenControllerInterface {
  using SafeMathUpgradeable for uint256;
  using SafeCastUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ERC165CheckerUpgradeable for address;

  event Initialized(
    address reserveRegistry,
    uint256 maxExitFeeMantissa,
    uint256 maxTimelockDuration
  );

  event ReserveFeeCaptured(
    uint256 amount
  );

  event AwardCaptured(
    uint256 amount
  );

  event Deposited(
    address indexed operator,
    address indexed to,
    address indexed token,
    uint256 amount,
    address referrer
  );

  event Awarded(
    address indexed winner,
    address indexed token,
    uint256 amount
  );

  event AwardedExternalERC20(
    address indexed winner,
    address indexed token,
    uint256 amount
  );

  event TransferredExternalERC20(
    address indexed to,
    address indexed token,
    uint256 amount
  );

  event AwardedExternalERC721(
    address indexed winner,
    address indexed token,
    uint256[] tokenIds
  );

  event InstantWithdrawal(
    address indexed operator,
    address indexed from,
    address indexed token,
    uint256 amount,
    uint256 redeemed,
    uint256 exitFee
  );

  event ReserveWithdrawal(
    address indexed to,
    uint256 amount
  );

  event LiquidityCapSet(
    uint256 liquidityCap
  );

  event CreditPlanSet(
    address token,
    uint128 creditLimitMantissa,
    uint128 creditRateMantissa
  );

  event PrizeStrategySet(
    address indexed prizeStrategy
  );

  event CreditMinted(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  event CreditBurned(
    address indexed user,
    address indexed token,
    uint256 amount
  );

  struct CreditPlan {
    uint128 creditLimitMantissa;
    uint128 creditRateMantissa;
  }

  struct CreditBalance {
    uint192 balance;
    uint32 timestamp;
    bool initialized;
  }

  RegistryInterface public reserveRegistry;
  TokenListenerInterface public prizeStrategy;
  uint256 public maxExitFeeMantissa;
  uint256 public maxTimelockDuration;
  uint256 public reserveTotalSupply;
  uint256 public liquidityCap;  
  ControlledTokenInterface public ticket;
  
  uint256 internal _currentAwardBalance;
  mapping(address => CreditPlan) internal _tokenCreditPlans;
  mapping(address => mapping(address => CreditBalance)) internal _tokenCreditBalances;

  function initialize (
    RegistryInterface _reserveRegistry,
    ControlledTokenInterface _ticket,
    uint256 _maxExitFeeMantissa,
    uint256 _maxTimelockDuration
  )
    public
    initializer
  {
    require(address(_reserveRegistry) != address(0), "PRIZEPOOL: RESERVEREGISTRY_NOT_ZERO");
    ticket = _ticket;

    __Ownable_init();
    __ReentrancyGuard_init();
    _setLiquidityCap(uint256(-1));

    reserveRegistry = _reserveRegistry;
    maxExitFeeMantissa = _maxExitFeeMantissa;
    maxTimelockDuration = _maxTimelockDuration;

    emit Initialized(
      address(_reserveRegistry),
      maxExitFeeMantissa,
      maxTimelockDuration
    );
  }

  function depositTo(
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  )
    external override
    onlyTicket(controlledToken)
    canAddLiquidity(amount)
    nonReentrant
  {
    address operator = _msgSender();

    uint256 mintAmount = amount.sub(amount.div(10));
    _mint(to, mintAmount, controlledToken);
    
    _token().safeTransferFrom(operator, address(this), amount);
    _supply(amount);

    emit Deposited(operator, to, controlledToken, amount, referrer);
  }

  function withdrawInstantlyFrom(
    address from,
    uint256 amount,
    address controlledToken,
    uint256 maximumExitFee
  )
    external override
    nonReentrant
    onlyTicket(controlledToken)
    returns (uint256)
  {
    (uint256 exitFee, uint256 burnedCredit) = _calculateEarlyExitFeeLessBurnedCredit(from, controlledToken, amount);
    require(exitFee <= maximumExitFee, "PRIZEPOOL: EXIT_FEE_EXCEEDS_USER_MAXIMUM");

    _burnCredit(from, controlledToken, burnedCredit);
    ControlledToken(controlledToken).controllerBurnFrom(_msgSender(), from, amount);
    uint256 amountLessFee = amount.sub(exitFee);
    uint256 redeemed = _redeem(amountLessFee);
    _token().safeTransfer(from, redeemed);
    emit InstantWithdrawal(_msgSender(), from, controlledToken, amount, redeemed, exitFee);
    return exitFee;
  }

  function withdrawReserve(address to) external override onlyReserve returns (uint256) {
    uint256 amount = reserveTotalSupply;
    reserveTotalSupply = 0;
    uint256 redeemed = _redeem(amount);
    _token().safeTransfer(address(to), redeemed);
    emit ReserveWithdrawal(to, amount);
    return redeemed;
  }

  function captureAwardBalance() external override nonReentrant returns (uint256) {
    uint256 tokenTotalSupply = _tokenTotalSupply();
    uint256 currentBalance = _balance();
    uint256 totalInterest = (currentBalance > tokenTotalSupply) ? currentBalance.sub(tokenTotalSupply) : 0;
    uint256 unaccountedPrizeBalance = (totalInterest > _currentAwardBalance) ? totalInterest.sub(_currentAwardBalance) : 0;

    if (unaccountedPrizeBalance > 0) {
      uint256 reserveFee = calculateReserveFee(unaccountedPrizeBalance);
      if (reserveFee > 0) {
        reserveTotalSupply = reserveTotalSupply.add(reserveFee);
        unaccountedPrizeBalance = unaccountedPrizeBalance.sub(reserveFee);
        emit ReserveFeeCaptured(reserveFee);
      }
      _currentAwardBalance = _currentAwardBalance.add(unaccountedPrizeBalance);
      emit AwardCaptured(unaccountedPrizeBalance);
    }

    return _currentAwardBalance;
  }

  function award(
    address to,
    uint256 amount,
    address controlledToken
  )
    external override
    onlyPrizeStrategy
    onlyTicket(controlledToken)
  {
    if (amount == 0) {
      return;
    }

    require(amount <= _currentAwardBalance, "PRIZEPOOL: AWARD_EXCEEDS_CURRENT_BALANCE");
    
    _currentAwardBalance = _currentAwardBalance.sub(amount);
    _mint(to, amount, controlledToken);
    uint256 extraCredit = _calculateEarlyExitFeeNoCredit(controlledToken, amount);
    _accrueCredit(to, controlledToken, IERC20Upgradeable(controlledToken).balanceOf(to), extraCredit);

    emit Awarded(to, controlledToken, amount);
  }

  function awardExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external override
    onlyPrizeStrategy
  {
    if (_transferOut(to, externalToken, amount)) {
      emit AwardedExternalERC20(to, externalToken, amount);
    }
  }

  function awardExternalERC721(
    address to,
    address externalToken,
    uint256[] calldata tokenIds
  )
    external override
    onlyPrizeStrategy
  {
    require(_canAwardExternal(externalToken), "PRIZEPOOL: INVALID_EXTERNAL_TOKEN");

    if (tokenIds.length == 0) {
      return;
    }

    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721Upgradeable(externalToken).transferFrom(address(this), to, tokenIds[i]);
    }

    emit AwardedExternalERC721(to, externalToken, tokenIds);
  }

  function calculateEarlyExitFee(
    address from,
    address controlledToken,
    uint256 amount
  )
    external override
    returns (
      uint256 exitFee,
      uint256 burnedCredit
    )
  {
    return _calculateEarlyExitFeeLessBurnedCredit(from, controlledToken, amount);
  }

  function calculateReserveFee(uint256 amount) public view returns (uint256) {
    ReserveInterface reserve = ReserveInterface(reserveRegistry.lookup());
    if (address(reserve) == address(0)) {
      return 0;
    }
    uint256 reserveRateMantissa = reserve.reserveRateMantissa();
    if (reserveRateMantissa == 0) {
      return 0;
    }
    return FixedPoint.multiplyUintByMantissa(amount, reserveRateMantissa);
  }

  function estimateCreditAccrualTime(
    address _controlledToken,
    uint256 _principal,
    uint256 _interest
  )
    external override
    view
    returns (uint256 durationSeconds)
  {
    return _estimateCreditAccrualTime(_controlledToken, _principal, _interest);
  }

  function setCreditPlanOf(
    address _controlledToken,
    uint128 _creditRateMantissa,
    uint128 _creditLimitMantissa
  )
    external override
    onlyTicket(_controlledToken)
    onlyOwner
  {
    _tokenCreditPlans[_controlledToken] = CreditPlan({
      creditLimitMantissa: _creditLimitMantissa,
      creditRateMantissa: _creditRateMantissa
    });

    emit CreditPlanSet(_controlledToken, _creditLimitMantissa, _creditRateMantissa);
  }

  function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
    _setLiquidityCap(_liquidityCap);
  }

  function setPrizeStrategy(TokenListenerInterface _prizeStrategy) external override onlyOwner {
    _setPrizeStrategy(_prizeStrategy);
  }

  function token() external override view returns (address) {
    return address(_token());
  }

  function balance() external returns (uint256) {
    return _balance();
  }

  function canAwardExternal(address _externalToken) external view returns (bool) {
    return _canAwardExternal(_externalToken);
  }

  function awardBalance() external override view returns (uint256) {
    return _currentAwardBalance;
  }

  function accountedBalance() external override view returns (uint256) {
    return _tokenTotalSupply();
  }

  function balanceOfCredit(address user, address controlledToken) external override onlyTicket(controlledToken) returns (uint256) {
    _accrueCredit(user, controlledToken, IERC20Upgradeable(controlledToken).balanceOf(user), 0);
    return _tokenCreditBalances[controlledToken][user].balance;
  }

  function creditPlanOf(
    address controlledToken
  )
    external override view
    returns (
      uint128 creditLimitMantissa,
      uint128 creditRateMantissa
    )
  {
    creditLimitMantissa = _tokenCreditPlans[controlledToken].creditLimitMantissa;
    creditRateMantissa = _tokenCreditPlans[controlledToken].creditRateMantissa;
  }

  function transferExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external override
    onlyPrizeStrategy
  {
    if (_transferOut(to, externalToken, amount)) {
      emit TransferredExternalERC20(to, externalToken, amount);
    }
  }

  function beforeTokenTransfer(address from, address to, uint256 amount) external override onlyTicket(msg.sender) {
    if (from != address(0)) {
      uint256 fromBeforeBalance = IERC20Upgradeable(msg.sender).balanceOf(from);
      uint256 newCreditBalance = _calculateCreditBalance(from, msg.sender, fromBeforeBalance, 0);

      if (from != to) {
        newCreditBalance = _applyCreditLimit(msg.sender, fromBeforeBalance.sub(amount), newCreditBalance);
      }

      _updateCreditBalance(from, msg.sender, newCreditBalance);
    }
    if (to != address(0) && to != from) {
      _accrueCredit(to, msg.sender, IERC20Upgradeable(msg.sender).balanceOf(to), 0);
    }
    if (from != address(0) && address(prizeStrategy) != address(0)) {
      prizeStrategy.beforeTokenTransfer(from, to, amount, msg.sender);
    }
  }
 
  function calculateTimelockDuration(
    address from,
    address controlledToken,
    uint256 amount
  )
    external override
    returns (
      uint256 durationSeconds,
      uint256 burnedCredit
    )
  {
    return _calculateTimelockDuration(from, controlledToken, amount);
  }
  
  function _limitExitFee(uint256 withdrawalAmount, uint256 exitFee) internal view returns (uint256) {
    uint256 maxFee = FixedPoint.multiplyUintByMantissa(withdrawalAmount, maxExitFeeMantissa);
    if (exitFee > maxFee) {
      exitFee = maxFee;
    }
    return exitFee;
  }

  function _transferOut(
    address to,
    address externalToken,
    uint256 amount
  )
    internal
    returns (bool)
  {
    require(_canAwardExternal(externalToken), "PRIZEPOOL: INVALID_EXTERNAL_TOKEN");

    if (amount == 0) {
      return false;
    }
    IERC20Upgradeable(externalToken).safeTransfer(to, amount);
    return true;
  }

  function _mint(address to, uint256 amount, address controlledToken) internal {
    if (address(prizeStrategy) != address(0)) {
      prizeStrategy.beforeTokenMint(to, amount, controlledToken);
    }
    ControlledToken(controlledToken).controllerMint(to, amount);
  }

  function _calculateTimelockDuration(
    address from,
    address controlledToken,
    uint256 amount
  )
    internal
    returns (
      uint256 durationSeconds,
      uint256 burnedCredit
    )
  {
    (uint256 exitFee, uint256 _burnedCredit) = _calculateEarlyExitFeeLessBurnedCredit(from, controlledToken, amount);
    uint256 duration = _estimateCreditAccrualTime(controlledToken, amount, exitFee);
    if (duration > maxTimelockDuration) {
      duration = maxTimelockDuration;
    }
    return (duration, _burnedCredit);
  }

  function _calculateEarlyExitFeeNoCredit(address controlledToken, uint256 amount) internal view returns (uint256) {
    return _limitExitFee(
      amount,
      FixedPoint.multiplyUintByMantissa(amount, _tokenCreditPlans[controlledToken].creditLimitMantissa)
    );
  }

  function _estimateCreditAccrualTime(
    address _controlledToken,
    uint256 _principal,
    uint256 _interest
  )
    internal
    view
    returns (uint256 durationSeconds)
  {
    uint256 accruedPerSecond = FixedPoint.multiplyUintByMantissa(_principal, _tokenCreditPlans[_controlledToken].creditRateMantissa);
    if (accruedPerSecond == 0) {
      return 0;
    }
    return _interest.div(accruedPerSecond);
  }

  function _burnCredit(address user, address controlledToken, uint256 credit) internal {
    _tokenCreditBalances[controlledToken][user].balance = uint256(_tokenCreditBalances[controlledToken][user].balance).sub(credit).toUint128();

    emit CreditBurned(user, controlledToken, credit);
  }

  function _accrueCredit(address user, address controlledToken, uint256 controlledTokenBalance, uint256 extra) internal {
    _updateCreditBalance(
      user,
      controlledToken,
      _calculateCreditBalance(user, controlledToken, controlledTokenBalance, extra)
    );
  }

  function _calculateCreditBalance(address user, address controlledToken, uint256 controlledTokenBalance, uint256 extra) internal view returns (uint256) {
    uint256 newBalance;
    CreditBalance storage creditBalance = _tokenCreditBalances[controlledToken][user];
    if (!creditBalance.initialized) {
      newBalance = 0;
    } else {
      uint256 credit = _calculateAccruedCredit(user, controlledToken, controlledTokenBalance);
      newBalance = _applyCreditLimit(controlledToken, controlledTokenBalance, uint256(creditBalance.balance).add(credit).add(extra));
    }
    return newBalance;
  }

  function _updateCreditBalance(address user, address controlledToken, uint256 newBalance) internal {
    uint256 oldBalance = _tokenCreditBalances[controlledToken][user].balance;

    _tokenCreditBalances[controlledToken][user] = CreditBalance({
      balance: newBalance.toUint128(),
      timestamp: _currentTime().toUint32(),
      initialized: true
    });

    if (oldBalance < newBalance) {
      emit CreditMinted(user, controlledToken, newBalance.sub(oldBalance));
    } else {
      emit CreditBurned(user, controlledToken, oldBalance.sub(newBalance));
    }
  }

  function _applyCreditLimit(address controlledToken, uint256 controlledTokenBalance, uint256 creditBalance) internal view returns (uint256) {
    uint256 creditLimit = FixedPoint.multiplyUintByMantissa(
      controlledTokenBalance,
      _tokenCreditPlans[controlledToken].creditLimitMantissa
    );
    if (creditBalance > creditLimit) {
      creditBalance = creditLimit;
    }

    return creditBalance;
  }

  function _calculateAccruedCredit(address user, address controlledToken, uint256 controlledTokenBalance) internal view returns (uint256) {
    uint256 userTimestamp = _tokenCreditBalances[controlledToken][user].timestamp;

    if (!_tokenCreditBalances[controlledToken][user].initialized) {
      return 0;
    }

    uint256 deltaTime = _currentTime().sub(userTimestamp);
    uint256 creditPerSecond = FixedPoint.multiplyUintByMantissa(controlledTokenBalance, _tokenCreditPlans[controlledToken].creditRateMantissa);
    return deltaTime.mul(creditPerSecond);
  }

  function _calculateEarlyExitFeeLessBurnedCredit(
    address from,
    address controlledToken,
    uint256 amount
  )
    internal
    returns (
      uint256 earlyExitFee,
      uint256 creditBurned
    )
  {
    uint256 controlledTokenBalance = IERC20Upgradeable(controlledToken).balanceOf(from);
    require(controlledTokenBalance >= amount, "PRIZEPOOL: INSUFFICIENT_FUNDS");
    _accrueCredit(from, controlledToken, controlledTokenBalance, 0);

    uint256 remainingExitFee = _calculateEarlyExitFeeNoCredit(controlledToken, controlledTokenBalance.sub(amount));
    uint256 availableCredit;
    if (_tokenCreditBalances[controlledToken][from].balance >= remainingExitFee) {
      availableCredit = uint256(_tokenCreditBalances[controlledToken][from].balance).sub(remainingExitFee);
    }

    uint256 totalExitFee = _calculateEarlyExitFeeNoCredit(controlledToken, amount);
    creditBurned = (availableCredit > totalExitFee) ? totalExitFee : availableCredit;
    earlyExitFee = totalExitFee.sub(creditBurned);
    return (earlyExitFee, creditBurned);
  }

  function _setLiquidityCap(uint256 _liquidityCap) internal {
    liquidityCap = _liquidityCap;
    emit LiquidityCapSet(_liquidityCap);
  }

  function _setPrizeStrategy(TokenListenerInterface _prizeStrategy) internal {
    require(address(_prizeStrategy) != address(0), "PRIZEPOOL: PRIZESTRATEGY_NOT_ZERO");
    require(address(_prizeStrategy).supportsInterface(TokenListenerLibrary.ERC165_INTERFACE_ID_TOKEN_LISTENER), "PRIZEPOOL: PRIZESTRATEGY_INVALID");
    prizeStrategy = _prizeStrategy;

    emit PrizeStrategySet(address(_prizeStrategy));
  }

  function _currentTime() internal virtual view returns (uint256) {
    return block.timestamp;
  }

  function _tokenTotalSupply() internal view returns (uint256) {
    uint256 total = reserveTotalSupply;
    total = total.add(IERC20Upgradeable(ticket).totalSupply());
    return total;
  }

  function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
    uint256 tokenTotalSupply = _tokenTotalSupply();
    return (tokenTotalSupply.add(_amount) <= liquidityCap);
  }

  function _canAwardExternal(address _externalToken) internal virtual view returns (bool);

  function _token() internal virtual view returns (IERC20Upgradeable);

  function _balance() internal virtual returns (uint256);

  function _supply(uint256 mintAmount) internal virtual;

  function _redeem(uint256 redeemAmount) internal virtual returns (uint256);

  modifier onlyTicket(address controlledToken) {
    require(address(ticket) == controlledToken, "PRIZEPOOL: ONLY_TICKET");
    _;
  }

  modifier onlyPrizeStrategy() {
    require(_msgSender() == address(prizeStrategy), "PRIZEPOOL: ONLY_PRIZESTRATEGY");
    _;
  }

  modifier canAddLiquidity(uint256 _amount) {
    require(_canAddLiquidity(_amount), "PRIZEPOOL: EXCEEDS_LIQUIDITY_CAP");
    _;
  }

  modifier onlyReserve() {
    ReserveInterface reserve = ReserveInterface(reserveRegistry.lookup());
    require(address(reserve) == msg.sender, "PRIZEPOOL: ONLY_RESERVE");
    _;
  }
}