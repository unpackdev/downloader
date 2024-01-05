// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./FixedPoint.sol";

import "./TokenListener.sol";
import "./TokenControllerInterface.sol";
import "./ControlledToken.sol";
import "./TicketInterface.sol";
import "./PrizePool.sol";
import "./Constants.sol";
import "./BeforeAwardListenerControlled.sol";

/* solium-disable security/no-block-members */
abstract contract ControlledStrategy is Initializable,
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

  event PrizePoolAwarded(
    address indexed operator
  );

  event TokenListenerUpdated(
    TokenListenerInterface indexed tokenListener
  );

  event PrizePeriodSecondsUpdated(
    uint256 prizePeriodSeconds
  );

  event BeforeAwardListenerSet(
    BeforeAwardListenerControlledInterface indexed beforeAwardListener
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
    IERC20Upgradeable[] externalErc20Awards
  );

  // Comptroller
  TokenListenerInterface public tokenListener;

  // Contract Interfaces
  PrizePool public prizePool;
  TicketInterface public ticket;
  IERC20Upgradeable public sponsorship;

  // Prize period
  uint256 public prizePeriodSeconds;
  uint256 public prizePeriodStartedAt;

  // External tokens awarded as part of prize
  MappedSinglyLinkedList.Mapping internal externalErc20s;
  MappedSinglyLinkedList.Mapping internal externalErc721s;

  // External NFT token IDs to be awarded
  //   NFT Address => TokenIds
  mapping (IERC721Upgradeable => uint256[]) internal externalErc721TokenIds;

  /// @notice A listener that is called before the prize is awarded
  BeforeAwardListenerControlledInterface public beforeAwardListener;

  /// @notice Initializes a new strategy
  /// @param _prizePeriodStart The starting timestamp of the prize period.
  /// @param _prizePeriodSeconds The duration of the prize period in seconds
  /// @param _prizePool The prize pool to award
  /// @param _ticket The ticket to use to draw winners
  /// @param _sponsorship The sponsorship token
  function initialize (
    uint256 _prizePeriodStart,
    uint256 _prizePeriodSeconds,
    PrizePool _prizePool,
    TicketInterface _ticket,
    IERC20Upgradeable _sponsorship,
    IERC20Upgradeable[] memory externalErc20Awards
  ) public initializer {
    require(address(_prizePool) != address(0), "ControlledStrategy/prize-pool-not-zero");
    require(address(_ticket) != address(0), "ControlledStrategy/ticket-not-zero");
    require(address(_sponsorship) != address(0), "ControlledStrategy/sponsorship-not-zero");
    prizePool = _prizePool;
    ticket = _ticket;
    sponsorship = _sponsorship;
    _setPrizePeriodSeconds(_prizePeriodSeconds);

    __Ownable_init();
    Constants.REGISTRY.setInterfaceImplementer(address(this), Constants.TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

    externalErc20s.initialize();
    for (uint256 i = 0; i < externalErc20Awards.length; i++) {
      _addExternalErc20Award(externalErc20Awards[i]);
    }

    prizePeriodSeconds = _prizePeriodSeconds;
    prizePeriodStartedAt = _prizePeriodStart;

    externalErc721s.initialize();

    emit Initialized(
      _prizePeriodStart,
      _prizePeriodSeconds,
      _prizePool,
      _ticket,
      _sponsorship,
      externalErc20Awards
    );
    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  function _distribute() internal virtual;

  /// @notice Calculates and returns the currently accrued prize
  /// @return The current prize size
  function currentPrize() public view returns (uint256) {
    return prizePool.awardBalance();
  }

  /// @notice Allows the owner to set the token listener
  /// @param _tokenListener A contract that implements the token listener interface.
  function setTokenListener(TokenListenerInterface _tokenListener) external onlyOwner {
    require(address(0) == address(_tokenListener) || address(_tokenListener).supportsInterface(TokenListenerLibrary.ERC165_INTERFACE_ID_TOKEN_LISTENER), "ControlledStrategy/token-listener-invalid");

    tokenListener = _tokenListener;

    emit TokenListenerUpdated(tokenListener);
  }

  /// @notice Estimates the remaining blocks until the prize given a number of seconds per block
  /// @param secondsPerBlockMantissa The number of seconds per block to use for the calculation.  Should be a fixed point 18 number like Ether.
  /// @return The estimated number of blocks remaining until the prize can be awarded.
  function estimateRemainingBlocksToPrize(uint256 secondsPerBlockMantissa) public view returns (uint256) {
    return FixedPoint.divideUintByMantissa(
      _prizePeriodRemainingSeconds(),
      secondsPerBlockMantissa
    );
  }

  /// @notice Returns the number of seconds remaining until the prize can be awarded.
  /// @return The number of seconds remaining until the prize can be awarded.
  function prizePeriodRemainingSeconds() external view returns (uint256) {
    return _prizePeriodRemainingSeconds();
  }

  /// @notice Returns the number of seconds remaining until the prize can be awarded.
  /// @return The number of seconds remaining until the prize can be awarded.
  function _prizePeriodRemainingSeconds() internal view returns (uint256) {
    uint256 endAt = _prizePeriodEndAt();
    uint256 time = _currentTime();
    if (time > endAt) {
      return 0;
    }
    return endAt.sub(time);
  }

  /// @notice Returns whether the prize period is over
  /// @return True if the prize period is over, false otherwise
  function isPrizePeriodOver() external view returns (bool) {
    return _isPrizePeriodOver();
  }

  /// @notice Returns whether the prize period is over
  /// @return True if the prize period is over, false otherwise
  function _isPrizePeriodOver() internal view returns (bool) {
    return _currentTime() >= _prizePeriodEndAt();
  }

  /// @notice Awards collateral as tickets to a user
  /// @param user The user to whom the tickets are minted
  /// @param amount The amount of interest to mint as tickets.
  function _awardTickets(address user, uint256 amount) internal {
    prizePool.award(user, amount, address(ticket));
  }

  /// @notice Awards all external tokens with non-zero balances to the given user.  The external tokens must be held by the PrizePool contract.
  /// @param winner The user to transfer the tokens to
  function _awardAllExternalTokens(address winner) internal {
    _awardExternalErc20s(winner);
    _awardExternalErc721s(winner);
  }

  /// @notice Awards all external ERC20 tokens with non-zero balances to the given user.
  /// The external tokens must be held by the PrizePool contract.
  /// @param winner The user to transfer the tokens to
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

  /// @notice Awards all external ERC721 tokens to the given user.
  /// The external tokens must be held by the PrizePool contract.
  /// @dev The list of ERC721s is reset after every award
  /// @param winner The user to transfer the tokens to
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

  /// @notice Returns the timestamp at which the prize period ends
  /// @return The timestamp at which the prize period ends.
  function prizePeriodEndAt() external view returns (uint256) {
    // current prize started at is non-inclusive, so add one
    return _prizePeriodEndAt();
  }

  /// @notice Returns the timestamp at which the prize period ends
  /// @return The timestamp at which the prize period ends.
  function _prizePeriodEndAt() internal view returns (uint256) {
    // current prize started at is non-inclusive, so add one
    return prizePeriodStartedAt.add(prizePeriodSeconds);
  }

  /// @notice Called by the PrizePool for transfers of controlled tokens
  /// @dev Note that this is only for *transfers*, not mints or burns
  /// @param controlledToken The type of collateral that is being sent
  function beforeTokenTransfer(address from, address to, uint256 amount, address controlledToken) external override onlyPrizePool {
    require(from != to, "ControlledStrategy/transfer-to-self");

    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenTransfer(from, to, amount, controlledToken);
    }
  }

  /// @notice Called by the PrizePool when minting controlled tokens
  /// @param controlledToken The type of collateral that is being minted
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
    if (address(tokenListener) != address(0)) {
      tokenListener.beforeTokenMint(to, amount, controlledToken, referrer);
    }
  }

  /// @notice returns the current time.  Used for testing.
  /// @return The current time (block.timestamp)
  function _currentTime() internal virtual view returns (uint256) {
    return block.timestamp;
  }

  /// @notice returns the current time.  Used for testing.
  /// @return The current time (block.timestamp)
  function _currentBlock() internal virtual view returns (uint256) {
    return block.number;
  }

  /// @notice Distributes the award
  function award() external onlyOwner requireCanDistributeAward {
    if (address(beforeAwardListener) != address(0)) {
      beforeAwardListener.beforePrizePoolAwarded(prizePeriodStartedAt);
    }
    _distribute();

    // to avoid clock drift, we should calculate the start time based on the previous period start time.
    prizePeriodStartedAt = _calculateNextPrizePeriodStartTime(_currentTime());

    emit PrizePoolAwarded(_msgSender());
    emit PrizePoolOpened(_msgSender(), prizePeriodStartedAt);
  }

  /// @notice Allows the owner to set a listener that is triggered immediately before the award is distributed
  /// @dev The listener must implement ERC165 and the BeforeAwardListenerInterface
  /// @param _beforeAwardListener The address of the listener contract
  function setBeforeAwardListener(BeforeAwardListenerControlledInterface _beforeAwardListener) external onlyOwner {
    require(
      address(0) == address(_beforeAwardListener) || address(_beforeAwardListener).supportsInterface(BeforeAwardListenerControlledLibrary.ERC165_INTERFACE_ID_BEFORE_AWARD_LISTENER),
      "ControlledStrategy/beforeAwardListener-invalid"
    );

    beforeAwardListener = _beforeAwardListener;

    emit BeforeAwardListenerSet(_beforeAwardListener);
  }

  function _calculateNextPrizePeriodStartTime(uint256 currentTime) internal view returns (uint256) {
    uint256 elapsedPeriods = currentTime.sub(prizePeriodStartedAt).div(prizePeriodSeconds);
    return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodSeconds));
  }

  /// @notice Calculates when the next prize period will start
  /// @param currentTime The timestamp to use as the current time
  /// @return The timestamp at which the next prize period would start
  function calculateNextPrizePeriodStartTime(uint256 currentTime) external view returns (uint256) {
    return _calculateNextPrizePeriodStartTime(currentTime);
  }

  /// @notice Allows the owner to set the prize period in seconds.
  /// @param _prizePeriodSeconds The new prize period in seconds.  Must be greater than zero.
  function setPrizePeriodSeconds(uint256 _prizePeriodSeconds) external onlyOwner {
    _setPrizePeriodSeconds(_prizePeriodSeconds);
  }

  /// @notice Sets the prize period in seconds.
  /// @param _prizePeriodSeconds The new prize period in seconds.  Must be greater than zero.
  function _setPrizePeriodSeconds(uint256 _prizePeriodSeconds) internal {
    require(_prizePeriodSeconds > 0, "ControlledStrategy/prize-period-greater-than-zero");
    prizePeriodSeconds = _prizePeriodSeconds;

    emit PrizePeriodSecondsUpdated(prizePeriodSeconds);
  }

  /// @notice Gets the current list of External ERC20 tokens that will be awarded with the current prize
  /// @return An array of External ERC20 token addresses
  function getExternalErc20Awards() external view returns (address[] memory) {
    return externalErc20s.addressArray();
  }

  /// @notice Adds an external ERC20 token type as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can assign external tokens,
  /// and they must be approved by the Prize-Pool
  /// @param _externalErc20 The address of an ERC20 token to be awarded
  function addExternalErc20Award(IERC20Upgradeable _externalErc20) external onlyOwner {
    _addExternalErc20Award(_externalErc20);
  }

  function _addExternalErc20Award(IERC20Upgradeable _externalErc20) internal {
    require(address(_externalErc20).isContract(), "ControlledStrategy/erc20-null");
    require(prizePool.canAwardExternal(address(_externalErc20)), "ControlledStrategy/cannot-award-external");
    (bool succeeded, bytes memory returnValue) = address(_externalErc20).staticcall(abi.encodeWithSignature("totalSupply()"));
    require(succeeded, "ControlledStrategy/erc20-invalid");
    externalErc20s.addAddress(address(_externalErc20));
    emit ExternalErc20AwardAdded(_externalErc20);
  }

  function addExternalErc20Awards(IERC20Upgradeable[] calldata _externalErc20s) external onlyOwner {
    for (uint256 i = 0; i < _externalErc20s.length; i++) {
      _addExternalErc20Award(_externalErc20s[i]);
    }
  }

  /// @notice Removes an external ERC20 token type as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can remove external tokens
  /// @param _externalErc20 The address of an ERC20 token to be removed
  /// @param _prevExternalErc20 The address of the previous ERC20 token in the `externalErc20s` list.
  /// If the ERC20 is the first address, then the previous address is the SENTINEL address: 0x0000000000000000000000000000000000000001
  function removeExternalErc20Award(IERC20Upgradeable _externalErc20, IERC20Upgradeable _prevExternalErc20) external onlyOwner {
    externalErc20s.removeAddress(address(_prevExternalErc20), address(_externalErc20));
    emit ExternalErc20AwardRemoved(_externalErc20);
  }

  /// @notice Gets the current list of External ERC721 tokens that will be awarded with the current prize
  /// @return An array of External ERC721 token addresses
  function getExternalErc721Awards() external view returns (address[] memory) {
    return externalErc721s.addressArray();
  }

  /// @notice Gets the current list of External ERC721 tokens that will be awarded with the current prize
  /// @return An array of External ERC721 token addresses
  function getExternalErc721AwardTokenIds(IERC721Upgradeable _externalErc721) external view returns (uint256[] memory) {
    return externalErc721TokenIds[_externalErc721];
  }

  /// @notice Adds an external ERC721 token as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can assign external tokens,
  /// and they must be approved by the Prize-Pool
  /// NOTE: The NFT must already be owned by the Prize-Pool
  /// @param _externalErc721 The address of an ERC721 token to be awarded
  /// @param _tokenIds An array of token IDs of the ERC721 to be awarded
  function addExternalErc721Award(IERC721Upgradeable _externalErc721, uint256[] calldata _tokenIds) external onlyOwner {
    require(prizePool.canAwardExternal(address(_externalErc721)), "ControlledStrategy/cannot-award-external");
    require(address(_externalErc721).supportsInterface(Constants.ERC165_INTERFACE_ID_ERC721), "ControlledStrategy/erc721-invalid");
    
    if (!externalErc721s.contains(address(_externalErc721))) {
      externalErc721s.addAddress(address(_externalErc721));
    }

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _addExternalErc721Award(_externalErc721, _tokenIds[i]);
    }

    emit ExternalErc721AwardAdded(_externalErc721, _tokenIds);
  }

  function _addExternalErc721Award(IERC721Upgradeable _externalErc721, uint256 _tokenId) internal {
    require(IERC721Upgradeable(_externalErc721).ownerOf(_tokenId) == address(prizePool), "ControlledStrategy/unavailable-token");
    for (uint256 i = 0; i < externalErc721TokenIds[_externalErc721].length; i++) {
      if (externalErc721TokenIds[_externalErc721][i] == _tokenId) {
        revert("ControlledStrategy/erc721-duplicate");
      }
    }
    externalErc721TokenIds[_externalErc721].push(_tokenId);
  }

  /// @notice Removes an external ERC721 token as an additional prize that can be awarded
  /// @dev Only the Prize-Strategy owner/creator can remove external tokens
  /// @param _externalErc721 The address of an ERC721 token to be removed
  /// @param _prevExternalErc721 The address of the previous ERC721 token in the list.
  /// If no previous, then pass the SENTINEL address: 0x0000000000000000000000000000000000000001
  function removeExternalErc721Award(
    IERC721Upgradeable _externalErc721,
    IERC721Upgradeable _prevExternalErc721
  )
    external
    onlyOwner
  {
    externalErc721s.removeAddress(address(_prevExternalErc721), address(_externalErc721));
    _removeExternalErc721AwardTokens(_externalErc721);
  }

  function _removeExternalErc721AwardTokens(
    IERC721Upgradeable _externalErc721
  )
    internal
  {
    delete externalErc721TokenIds[_externalErc721];
    emit ExternalErc721AwardRemoved(_externalErc721);
  }

  modifier requireCanDistributeAward() {
    require(_isPrizePeriodOver(), "ControlledStrategy/prize-period-not-over");
    _;
  }

  modifier onlyOwnerOrListener() {
    require(_msgSender() == owner() ||
            _msgSender() == address(beforeAwardListener),
            "ControlledStrategy/only-owner-or-listener");
    _;
  }

  modifier onlyPrizePool() {
    require(_msgSender() == address(prizePool), "ControlledStrategy/only-prize-pool");
    _;
  }
}
