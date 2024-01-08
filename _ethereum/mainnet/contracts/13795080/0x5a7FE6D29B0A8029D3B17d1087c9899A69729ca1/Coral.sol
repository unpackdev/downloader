// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ISharkGame.sol";
import "./ISharks.sol";
import "./IChum.sol";
import "./ICoral.sol";
import "./IRandomizer.sol";

contract Coral is ICoral, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    uint256 timestamp;
    address owner;
  }

  event TokenStaked(address indexed owner, uint256 indexed tokenId, ISharks.SGTokenType indexed tokenType);
  event TokenClaimed(uint256 indexed tokenId, bool indexed unstaked, ISharks.SGTokenType indexed tokenType, uint256 earned);

  // reference to the WnD NFT contract
  ISharks public sharksNft;
  // reference to the WnD NFT contract
  ISharkGame public sharkGame;
  // reference to the $CHUM contract for minting $CHUM earnings
  IChum public chumToken;
  // reference to Randomizer
  IRandomizer public randomizer;

  // count of each type staked
  mapping(ISharks.SGTokenType => uint16) public numStaked;
  // maps tokenId to stake
  mapping(uint16 => Stake) public coral;
  // maps types to all tokens staked of a given type
  mapping(ISharks.SGTokenType => uint16[]) public coralByType;
  // maps tokenId to index in coralByType
  mapping(uint16 => uint256) public  coralByTypeIndex;
  // any rewards distributed when none of a type are staked
  uint256[] public unaccountedRewards = [0, 0, 0];
  // amount of $CHUM stolen through fees by species
  // minnows never get any but are included for consistency
  uint256[] public chumStolen = [0, 0, 0];
  // have orcas been staked yet
  bool public orcasEnabled = false;

  // array indices map to SGTokenType enum entries
  // minnows earn 10000 chum per day
  // sharks earn 0 chum per day but get fees
  // orcas earn 20000 chum per day
  uint256[] public DAILY_CHUM_RATES = [10000 ether, 0, 20000 ether];
  // wizards must have 2 days worth of $CHUM to unstake or else they're still guarding the tower
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // sharks have a 5% chance of losing all earnings on being unstaked
  uint256 public constant SHARK_RISK_CHANCE = 5;
  // sharks take a 20% tax on all $CHUM claimed by minnows
  uint256 public constant MINNOW_CLAIM_TAX = 20;
  // orcas take a 10% tax on all $CHUM claimed by sharks
  uint256 public constant SHARK_CLAIM_TAX = 10;
  // there will only ever be (roughly) 5 billion $CHUM earned through staking
  uint256 public constant MAXIMUM_GLOBAL_CHUM = 5000000000 ether;

  // amount of $CHUM earned so far
  uint256 public totalChumEarned;
  // the last time $CHUM was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $CHUM
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(sharksNft) != address(0) && address(chumToken) != address(0)
        && address(sharkGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _sharksNft, address _chum, address _sharkGame, address _rand) external onlyOwner {
    sharksNft = ISharks(_sharksNft);
    chumToken = IChum(_chum);
    sharkGame = ISharkGame(_sharkGame);
    randomizer = IRandomizer(_rand);
  }

  /** STAKING */

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToCoral(address account, uint16[] calldata tokenIds) external override _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(sharkGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      if (_msgSender() != address(sharkGame)) { // dont do this step if its a mint + stake
        require(sharksNft.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        sharksNft.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenId == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      ISharks.SGTokenType tokenType = sharksNft.getTokenType(tokenId);
      coral[tokenId] = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(chumStolen[uint8(tokenType)]),
        timestamp: block.timestamp
      });
      coralByTypeIndex[tokenId] = coralByType[tokenType].length;
      coralByType[tokenType].push(tokenId);
      numStaked[tokenType] += 1;
      if (tokenType == ISharks.SGTokenType.ORCA) {
        orcasEnabled = true;
      }
      emit TokenStaked(account, tokenId, tokenType);
    }
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $CHUM earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $CHUM unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromCoral(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(sharkGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      Stake memory stake = coral[tokenId];
      require(stake.owner != address(0), "Token is not staked");
      uint256 tokenOwed = this.calculateRewards(stake);
      ISharks.SGTokenType tokenType = sharksNft.getTokenType(tokenId);

      if (unstake) {
        // changed to a random orca holder if this token is stolen by an orca
        address recipient = _msgSender();
        if (tokenType == ISharks.SGTokenType.MINNOW) {
          // minnows have a 50% chance of losing all earnings on being unstaked
          if (randomizer.random() & 1 == 1) {
            uint256 orcasSteal = tokenOwed * 3 / 10;
            _payTax(orcasSteal, ISharks.SGTokenType.ORCA);
            _payTax(tokenOwed - orcasSteal, ISharks.SGTokenType.SHARK);
            tokenOwed = 0;
          }
        } else if (tokenType == ISharks.SGTokenType.SHARK) {
          uint256 seed = randomizer.random();
          // 5% chance of orca stealing the shark on unstake
          if (orcasEnabled && (seed & 0xFFFF) % 100 < SHARK_RISK_CHANCE) {
            // change the recipient to a random orca owner
            recipient = this.randomTokenOwner(ISharks.SGTokenType.ORCA, seed);
          }
        }

        delete coral[tokenId];
        if (coralByType[tokenType].length > 1) {
          coralByTypeIndex[coralByType[tokenType][coralByType[tokenType].length - 1]] = coralByTypeIndex[tokenId];
          coralByType[tokenType][coralByTypeIndex[tokenId]] = coralByType[tokenType][coralByType[tokenType].length - 1];
        }
        coralByType[tokenType].pop();
        numStaked[tokenType] -= 1;
        // Always transfer last to guard against reentrancy
        sharksNft.safeTransferFrom(address(this), recipient, tokenId, "");
      } else {
        if (tokenType == ISharks.SGTokenType.MINNOW) {
          uint256 sharksSteal = tokenOwed * MINNOW_CLAIM_TAX / 100;
          _payTax(sharksSteal, ISharks.SGTokenType.SHARK);
          tokenOwed -= sharksSteal;
        } else if (tokenType == ISharks.SGTokenType.SHARK && orcasEnabled) {
          uint256 orcasSteal = tokenOwed * SHARK_CLAIM_TAX / 100;
          _payTax(orcasSteal, ISharks.SGTokenType.ORCA);
          tokenOwed -= orcasSteal;
        }
        coral[tokenId] = Stake({
          owner: _msgSender(),
          tokenId: uint16(tokenId),
          value: uint80(chumStolen[uint8(tokenType)]),
          timestamp: block.timestamp
        }); // reset stake
      }
      owed += tokenOwed;
      emit TokenClaimed(tokenId, unstake, tokenType, owed);
    }
    chumToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    chumToken.mint(_msgSender(), owed);
  }

  function calculateRewards(Stake calldata stake) external view returns (uint256 owed) {
    uint64 lastTokenWrite = sharksNft.getTokenWriteBlock(stake.tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    uint8 tokenType = uint8(sharksNft.getTokenType(stake.tokenId));
    uint256 dailyRate = DAILY_CHUM_RATES[tokenType];
    if (dailyRate > 0) {
      if (totalChumEarned < MAXIMUM_GLOBAL_CHUM) {
        owed = (block.timestamp - stake.timestamp) * DAILY_CHUM_RATES[tokenType] / 1 days;
      } else if (stake.timestamp > lastClaimTimestamp) {
        owed = 0; // $CHUM production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.timestamp) * DAILY_CHUM_RATES[tokenType] / 1 days; // stop earning additional $CHUM if it's all been earned
      }
    }
    owed += chumStolen[tokenType] - stake.value;
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint16[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint16 tokenId;
    ISharks.SGTokenType tokenType;
    Stake memory stake;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      tokenType = sharksNft.getTokenType(tokenId);
      stake = coral[tokenId];
      require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
      delete coral[tokenId];
      if (coralByType[tokenType].length > 1) {
        coralByTypeIndex[coralByType[tokenType][coralByType[tokenType].length - 1]] = coralByTypeIndex[tokenId];
        coralByType[tokenType][coralByTypeIndex[tokenId]] = coralByType[tokenType][coralByType[tokenType].length - 1];
      }
      coralByType[tokenType].pop();
      numStaked[tokenType] -= 1;
      // Always transfer last to guard against reentrancy
      sharksNft.safeTransferFrom(address(this), _msgSender(), tokenId, "");
      emit TokenClaimed(tokenId, true, tokenType, 0);
    }
  }

  /** ACCOUNTING */

  /**
   * add $CHUM to claimable pot for the Flight
   * @param amount $CHUM to add to the pot
   */
  function _payTax(uint256 amount, ISharks.SGTokenType tokenType) internal {
    if (numStaked[tokenType] == 0) { // if there's no staked sharks/orcas
      unaccountedRewards[uint8(tokenType)] += amount; // keep track of $CHUM due to sharks/orcas
      return;
    }
    // makes sure to include any unaccounted $CHUM
    chumStolen[uint8(tokenType)] += (amount + unaccountedRewards[uint8(tokenType)]) / numStaked[tokenType];
    unaccountedRewards[uint8(tokenType)] = 0;
  }

  /**
   * tracks $CHUM earnings to ensure it stops once 2.5 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalChumEarned < MAXIMUM_GLOBAL_CHUM) {
      totalChumEarned +=
        (block.timestamp - lastClaimTimestamp)
        * numStaked[ISharks.SGTokenType.MINNOW]
        * DAILY_CHUM_RATES[uint8(ISharks.SGTokenType.MINNOW)] / 1 days
      + (block.timestamp - lastClaimTimestamp)
        * numStaked[ISharks.SGTokenType.ORCA]
        * DAILY_CHUM_RATES[uint8(ISharks.SGTokenType.ORCA)] / 1 days;
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * chooses a random Dragon thief when a newly minted token is stolen
   * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
  function randomTokenOwner(ISharks.SGTokenType tokenType, uint256 seed) external view override returns (address) {
    uint256 numStakedOfType = numStaked[tokenType];
    if (numStakedOfType == 0) {
      return address(0x0);
    }
    uint256 i = (seed & 0xFFFFFFFF) % numStakedOfType; // choose a value from 0 to total rank staked
    return coral[coralByType[tokenType][i]].owner;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Coral directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}
