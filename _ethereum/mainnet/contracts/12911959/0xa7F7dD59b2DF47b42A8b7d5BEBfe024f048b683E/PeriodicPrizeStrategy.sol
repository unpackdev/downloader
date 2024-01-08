// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

import "./Constants.sol";
import "./FixedPoint.sol";

import "./RNGInterface.sol";
import "./TokenControllerInterface.sol";
import "./TicketInterface.sol";
import "./PeriodicPrizeStrategyListenerInterface.sol";
import "./PeriodicPrizeStrategyListenerLibrary.sol";

import "./BeforeAwardListener.sol";
import "./TokenListener.sol";
import "./ControlledToken.sol";
import "./PrizePool.sol";


/* solium-disable security/no-block-members */
abstract contract PeriodicPrizeStrategy is Initializable,
                                           OwnableUpgradeable,
                                           TokenListener {

  using SafeMathUpgradeable for uint256;
  using SafeCastUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using AddressUpgradeable for address;
  using ERC165CheckerUpgradeable for address;

  uint256 internal constant ETHEREUM_BLOCK_TIME_ESTIMATE_MANTISSA = 13.4 ether;

  event PrizePoolOpened(
    address indexed operator,
    uint256 indexed prizePeriodStartedAt
  );

  event RngRequestFailed();

  event PrizePoolAwardStarted(
    address indexed operator,
    address indexed prizePool,
    uint32 indexed rngRequestId,
    uint32 rngLockBlock
  );

  event PrizePoolAwardCancelled(
    address indexed operator,
    address indexed prizePool,
    uint32 indexed rngRequestId,
    uint32 rngLockBlock
  );

  event PrizePoolAwarded(
    address indexed operator,
    uint256 randomNumber
  );

  event RngServiceUpdated(
    RNGInterface indexed rngService
  );

  event TokenListenerUpdated(
    TokenListenerInterface indexed tokenListener
  );

  event RngRequestTimeoutSet(
    uint32 rngRequestTimeout
  );

  event PrizePeriodSecondsUpdated(
    uint256 prizePeriodSeconds
  );

  event BeforeAwardListenerSet(
    BeforeAwardListenerInterface indexed beforeAwardListener
  );

  event PeriodicPrizeStrategyListenerSet(
    PeriodicPrizeStrategyListenerInterface indexed periodicPrizeStrategyListener
  );

  event ExternalErc721AwardAdded(
    IERC721Upgradeable indexed externalErc721,
    uint256[] tokenIds
  );

  event ExternalErc20AwardAdded(
    IERC20Upgradeable indexed externalErc20
  );

  event ExternalErc721AwardRemoved(
    IERC721Upgradeable indexed externalErc721Award
  );

  event ExternalErc20AwardRemoved(
    IERC20Upgradeable indexed externalErc20Award
  );

  event Initialized(
    uint256 prizePeriodStart,
    uint256 prizePeriodSeconds,
    PrizePool indexed prizePool,
    TicketInterface ticket,
    IERC20Upgradeable sponsorship,
    RNGInterface rng,
    IERC20Upgradeable[] externalErc20Awards
  );

  struct RngRequest {
    uint32 id;
    uint32 lockBlock;
    uint32 requestedAt;
  }

  PrizePool public prizePool;
  TicketInterface public ticket;
  IERC20Upgradeable public sponsorship;
  RNGInterface public rng;
  uint256 public prizePeriodStartedAt;
  uint256 public prizePeriodSeconds;
  MappedSinglyLinkedList.Mapping internal externalErc20s;
  MappedSinglyLinkedList.Mapping internal externalErc721s;
  
  mapping (IERC721Upgradeable => uint256[]) internal externalErc721TokenIds;

  TokenListenerInterface public tokenListener;
  BeforeAwardListenerInterface public beforeAwardListener;
  PeriodicPrizeStrategyListenerInterface public periodicPrizeStrategyListener;

  RngRequest internal rngRequest;
  uint32 public rngRequestTimeout;

  function initialize (
    uint256 _prizePeriodStart,
    uint256 _prizePeriodSeconds,
    PrizePool _prizePool,
    TicketInterface _ticket,
    IERC20Upgradeable _sponsorship,
    RNGInterface _rng,
    IERC20Upgradeable[] memory externalErc20Awards
  ) public initializer {
    require(address(_prizePool) != address(0), "PERIODICPRIZESTRATEGY: PRIZE_POOL_NOT_ZERO");
    require(address(_ticket) != address(0), "PERIODICPRIZESTRATEGY: TICKET_NOT_ZERO");
    require(address(_sponsorship) != address(0), "PERIODICPRIZESTRATEGY: SPONSORSHIP_NOT_ZERO");
    require(address(_rng) != address(0), "PERIODICPRIZESTRATEGY: RNG_NOT_ZERO");
    
    prizePool = _prizePool;
    ticket = _ticket;
    rng = _rng;
    sponsorship = _sponsorship;    
    _setPrizePeriodSeconds(_prizePeriodSeconds);

    __Ownable_init();
    Constants.REGISTRY.setInterfaceImplementer(address(this), Constants.TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    externalErc20s.initialize();
    for (uint256 i = 0; i < externalErc20Awards.length; i++) {
      _addExternalErc20Award(externalErc20Awards[i]);
    }

    prizePeriodStartedAt = _prizePeriodStart;
    prizePeriodSeconds = _prizePeriodSeconds;

    externalErc721s.initialize();
    _setRngRequestTimeout(1800);

    emit Initialized(
      _prizePeriodStart,
      _prizePeriodSeconds,
      _prizePool,
      _ticket,
      _sponsorship,
      _rng,
      externalErc20Awards
    );
    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  function startAward() external requireCanStartAward {
    (address feeToken, uint256 requestFee) = rng.getRequestFee();
    if (feeToken != address(0) && requestFee > 0) {
      IERC20Upgradeable(feeToken).safeApprove(address(rng), requestFee);
    }

    (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
    rngRequest.id = requestId;
    rngRequest.lockBlock = lockBlock;
    rngRequest.requestedAt = _currentTime().toUint32();

    emit PrizePoolAwardStarted(_msgSender(), address(prizePool), requestId, lockBlock);
  }

  function completeAward() external requireCanCompleteAward {
    uint256 randomNumber = rng.randomNumber(rngRequest.id);
    delete rngRequest;

    if (address(beforeAwardListener) != address(0)) {
      beforeAwardListener.beforePrizePoolAwarded(randomNumber, prizePeriodStartedAt);
    }
    _distribute(randomNumber);
    if (address(periodicPrizeStrategyListener) != address(0)) {
      periodicPrizeStrategyListener.afterPrizePoolAwarded(randomNumber, prizePeriodStartedAt);
    }

    prizePeriodStartedAt = _calculateNextPrizePeriodStartTime(_currentTime());

    emit PrizePoolAwarded(_msgSender(), randomNumber);
    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  function cancelAward() public {
    require(isRngTimedOut(), "PERIODICPRIZESTRATEGY: RNG_NOT_TIMEDOUT");
    uint32 requestId = rngRequest.id;
    uint32 lockBlock = rngRequest.lockBlock;
    delete rngRequest;
    emit RngRequestFailed();
    emit PrizePoolAwardCancelled(msg.sender, address(prizePool), requestId, lockBlock);
  }

  function estimateRemainingBlocksToPrize(uint256 secondsPerBlockMantissa) public view returns (uint256) {
    return FixedPoint.divideUintByMantissa(
      _prizePeriodRemainingSeconds(),
      secondsPerBlockMantissa
    );
  }

  function calculateNextPrizePeriodStartTime(uint256 currentTime) external view returns (uint256) {
    return _calculateNextPrizePeriodStartTime(currentTime);
  }

  function beforeTokenTransfer(address from, address to, uint256 amount, address controlledToken) external override onlyPrizePool {
    require(from != to, "PERIODICPRIZESTRATEGY: TRANSFER_TO_SELF");

    if (controlledToken == address(ticket)) {
      _requireAwardNotInProgress();
    }

    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenTransfer(from, to, amount, controlledToken);
    }
  }

  function beforeTokenMint(
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  )
    external
    override
    onlyPrizePool
  {
    if (controlledToken == address(ticket)) {
      _requireAwardNotInProgress();
    }
    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenMint(to, amount, controlledToken, referrer);
    }
  }

  function setTokenListener(TokenListenerInterface _tokenListener) external onlyOwner requireAwardNotInProgress {
    require(address(0) == address(_tokenListener) || address(_tokenListener).supportsInterface(TokenListenerLibrary.ERC165_INTERFACE_ID_TOKEN_LISTENER), "PERIODICPRIZESTRATEGY: TOKEN_LISTERNER_INVALID");
    tokenListener = _tokenListener;
    emit TokenListenerUpdated(tokenListener);
  }

  function setBeforeAwardListener(BeforeAwardListenerInterface _beforeAwardListener) external onlyOwner requireAwardNotInProgress {
    require(
      address(0) == address(_beforeAwardListener) || address(_beforeAwardListener).supportsInterface(BeforeAwardListenerLibrary.ERC165_INTERFACE_ID_BEFORE_AWARD_LISTENER),
      "PERIODICPRIZESTRATEGY: BEFOREAWARDLISTENER_INVALID"
    );

    beforeAwardListener = _beforeAwardListener;
    emit BeforeAwardListenerSet(_beforeAwardListener);
  }

  function setPeriodicPrizeStrategyListener(PeriodicPrizeStrategyListenerInterface _periodicPrizeStrategyListener) external onlyOwner requireAwardNotInProgress {
    require(
      address(0) == address(_periodicPrizeStrategyListener) || address(_periodicPrizeStrategyListener).supportsInterface(PeriodicPrizeStrategyListenerLibrary.ERC165_INTERFACE_ID_PERIODIC_PRIZE_STRATEGY_LISTENER),
      "PERIODICPRIZESTRATEGY: PRIZESTRATEGYLISTERNER_INVALID"
    );

    periodicPrizeStrategyListener = _periodicPrizeStrategyListener;
    emit PeriodicPrizeStrategyListenerSet(_periodicPrizeStrategyListener);
  }

 function setRngService(RNGInterface rngService) external onlyOwner requireAwardNotInProgress {
    require(!isRngRequested(), "PERIODICPRIZESTRATEGY: RNG_IN_FLIGHT");

    rng = rngService;
    emit RngServiceUpdated(rngService);
  }

  function setRngRequestTimeout(uint32 _rngRequestTimeout) external onlyOwner requireAwardNotInProgress {
    _setRngRequestTimeout(_rngRequestTimeout);
  }

  function setPrizePeriodSeconds(uint256 _prizePeriodSeconds) external onlyOwner requireAwardNotInProgress {
    _setPrizePeriodSeconds(_prizePeriodSeconds);
  }

  function addExternalErc20Awards(IERC20Upgradeable[] calldata _externalErc20s) external onlyOwnerOrListener requireAwardNotInProgress {
    for (uint256 i = 0; i < _externalErc20s.length; i++) {
      _addExternalErc20Award(_externalErc20s[i]);
    }
  }

  function removeExternalErc20Award(IERC20Upgradeable _externalErc20, IERC20Upgradeable _prevExternalErc20) external onlyOwner requireAwardNotInProgress {
    externalErc20s.removeAddress(address(_prevExternalErc20), address(_externalErc20));
    emit ExternalErc20AwardRemoved(_externalErc20);
  }

  function addExternalErc721Award(IERC721Upgradeable _externalErc721, uint256[] calldata _tokenIds) external onlyOwnerOrListener requireAwardNotInProgress {
    require(prizePool.canAwardExternal(address(_externalErc721)), "PERIODICPRIZESTRATEGY: CANNOT_AWARD_EXTERNAL");
    require(address(_externalErc721).supportsInterface(Constants.ERC165_INTERFACE_ID_ERC721), "PERIODICPRIZESTRATEGY: ERC721_INVALID");
    
    if (!externalErc721s.contains(address(_externalErc721))) {
      externalErc721s.addAddress(address(_externalErc721));
    }

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _addExternalErc721Award(_externalErc721, _tokenIds[i]);
    }

    emit ExternalErc721AwardAdded(_externalErc721, _tokenIds);
  }

  function removeExternalErc721Award(
    IERC721Upgradeable _externalErc721,
    IERC721Upgradeable _prevExternalErc721
  )
    external
    onlyOwner
    requireAwardNotInProgress
  {
    externalErc721s.removeAddress(address(_prevExternalErc721), address(_externalErc721));
    _removeExternalErc721AwardTokens(_externalErc721);
  }

  function addExternalErc20Award(IERC20Upgradeable _externalErc20) external onlyOwnerOrListener requireAwardNotInProgress {
    _addExternalErc20Award(_externalErc20);
  }
  
  function getExternalErc20Awards() external view returns (address[] memory) {
    return externalErc20s.addressArray();
  }
  
  function prizePeriodRemainingSeconds() external view returns (uint256) {
    return _prizePeriodRemainingSeconds();
  }

  function currentPrize() public view returns (uint256) {
    return prizePool.awardBalance();
  }

  function isPrizePeriodOver() external view returns (bool) {
    return _isPrizePeriodOver();
  }

  function prizePeriodEndAt() external view returns (uint256) {
    return _prizePeriodEndAt();
  }

  function canStartAward() external view returns (bool) {
    return _isPrizePeriodOver() && !isRngRequested();
  }

  function canCompleteAward() external view returns (bool) {
    return isRngRequested() && isRngCompleted();
  }

  function isRngRequested() public view returns (bool) {
    return rngRequest.id != 0;
  }

  function isRngCompleted() public view returns (bool) {
    return rng.isRequestComplete(rngRequest.id);
  }

  function getLastRngLockBlock() external view returns (uint32) {
    return rngRequest.lockBlock;
  }

  function getLastRngRequestId() external view returns (uint32) {
    return rngRequest.id;
  }

  function getExternalErc721Awards() external view returns (address[] memory) {
    return externalErc721s.addressArray();
  }

  function getExternalErc721AwardTokenIds(IERC721Upgradeable _externalErc721) external view returns (uint256[] memory) {
    return externalErc721TokenIds[_externalErc721];
  }

  function isRngTimedOut() public view returns (bool) {
    if (rngRequest.requestedAt == 0) {
      return false;
    } else {
      return _currentTime() > uint256(rngRequestTimeout).add(rngRequest.requestedAt);
    }
  }

  function _addExternalErc721Award(IERC721Upgradeable _externalErc721, uint256 _tokenId) internal {
    require(IERC721Upgradeable(_externalErc721).ownerOf(_tokenId) == address(prizePool), "PERIODICPRIZESTRATEGY: UNAVAILABLE_TOKEN");
    for (uint256 i = 0; i < externalErc721TokenIds[_externalErc721].length; i++) {
      if (externalErc721TokenIds[_externalErc721][i] == _tokenId) {
        revert("PERIODICPRIZESTRATEGY: ERC721_DUPLICATE");
      }
    }
    externalErc721TokenIds[_externalErc721].push(_tokenId);
  }

  function _distribute(uint256 randomNumber) internal virtual;

  function _prizePeriodRemainingSeconds() internal view returns (uint256) {
    uint256 endAt = _prizePeriodEndAt();
    uint256 time = _currentTime();
    if (time > endAt) {
      return 0;
    }
    return endAt.sub(time);
  }

  function _isPrizePeriodOver() internal view returns (bool) {
    return _currentTime() >= _prizePeriodEndAt();
  }

  function _awardTickets(address user, uint256 amount) internal {
    prizePool.award(user, amount, address(ticket));
  }

  function _awardAllExternalTokens(address winner) internal {
    _awardExternalErc20s(winner);
    _awardExternalErc721s(winner);
  }

  function _awardExternalErc20s(address winner) internal {
    address currentToken = externalErc20s.start();
    while (currentToken != address(0) && currentToken != externalErc20s.end()) {
      uint256 balance = IERC20Upgradeable(currentToken).balanceOf(address(prizePool));
      if (balance > 0) {
        prizePool.awardExternalERC20(winner, currentToken, balance);
      }
      currentToken = externalErc20s.next(currentToken);
    }
  }

  function _awardExternalErc721s(address winner) internal {
    address currentToken = externalErc721s.start();
    while (currentToken != address(0) && currentToken != externalErc721s.end()) {
      uint256 balance = IERC721Upgradeable(currentToken).balanceOf(address(prizePool));
      if (balance > 0) {
        prizePool.awardExternalERC721(winner, currentToken, externalErc721TokenIds[IERC721Upgradeable(currentToken)]);
        _removeExternalErc721AwardTokens(IERC721Upgradeable(currentToken));
      }
      currentToken = externalErc721s.next(currentToken);
    }
    externalErc721s.clearAll();
  }

  function _prizePeriodEndAt() internal view returns (uint256) {
    return prizePeriodStartedAt.add(prizePeriodSeconds);
  }

  function _currentTime() internal virtual view returns (uint256) {
    return block.timestamp;
  }

  function _currentBlock() internal virtual view returns (uint256) {
    return block.number;
  }

  function _calculateNextPrizePeriodStartTime(uint256 currentTime) internal view returns (uint256) {
    uint256 elapsedPeriods = currentTime.sub(prizePeriodStartedAt).div(prizePeriodSeconds);
    return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodSeconds));
  }

  function _setRngRequestTimeout(uint32 _rngRequestTimeout) internal {
    require(_rngRequestTimeout > 60, "PeriodicPrizeStrategy/rng-timeout-gt-60-secs");
    rngRequestTimeout = _rngRequestTimeout;
    emit RngRequestTimeoutSet(rngRequestTimeout);
  }

  function _setPrizePeriodSeconds(uint256 _prizePeriodSeconds) internal {
    require(_prizePeriodSeconds > 0, "PERIODICPRIZESTRATEGY: PRIZE_PERIOD_GREATER_THAN_ZERO");
    prizePeriodSeconds = _prizePeriodSeconds;

    emit PrizePeriodSecondsUpdated(prizePeriodSeconds);
  }

  function _addExternalErc20Award(IERC20Upgradeable _externalErc20) internal {
    require(address(_externalErc20).isContract(), "PERIODICPRIZESTRATEGY: ERC20_NULL");
    require(prizePool.canAwardExternal(address(_externalErc20)), "PERIODICPRIZESTRATEGY: CANNOT_AWARD_EXTERNAL");
    (bool succeeded, bytes memory returnValue) = address(_externalErc20).staticcall(abi.encodeWithSignature("totalSupply()"));
    require(succeeded, "PERIODICPRIZESTRATEGY: ERC20_INVALID");
    externalErc20s.addAddress(address(_externalErc20));
    emit ExternalErc20AwardAdded(_externalErc20);
  }

  function _removeExternalErc721AwardTokens(
    IERC721Upgradeable _externalErc721
  )
    internal
  {
    delete externalErc721TokenIds[_externalErc721];
    emit ExternalErc721AwardRemoved(_externalErc721);
  }

  function _requireAwardNotInProgress() internal view {
    uint256 currentBlock = _currentBlock();
    require(rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock, "PERIODICPRIZESTRATEGY: RNG_IN_FLIGHT");
  }

  modifier onlyOwnerOrListener() {
    require(_msgSender() == owner() ||
            _msgSender() == address(periodicPrizeStrategyListener) ||
            _msgSender() == address(beforeAwardListener),
            "PERIODICPRIZESTRATEGY: ONLY_OWNER_OR_LISTENER");
    _;
  }

  modifier requireAwardNotInProgress() {
    _requireAwardNotInProgress();
    _;
  }

  modifier requireCanStartAward() {
    require(_isPrizePeriodOver(), "PERIODICPRIZESTRATEGY: PRIZE_PERIOD_NOT_OVER");
    require(!isRngRequested(), "PERIODICPRIZESTRATEGY: RNG_ALREADY_REQUESTED");
    _;
  }

  modifier requireCanCompleteAward() {
    require(isRngRequested(), "PERIODICPRIZESTRATEGY: RNG_NOT_REQUESTED");
    require(isRngCompleted(), "PERIODICPRIZESTRATEGY: RNG_NOT_COMPLETE");
    _;
  }

  modifier onlyPrizePool() {
    require(_msgSender() == address(prizePool), "PERIODICPRIZESTRATEGY: ONLY_PRIZE_POOL");
    _;
  }
}
