// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Squuid.sol";
import "./SQUID.sol";

import "./ReentrancyGuard.sol";

contract Arena is Ownable, IERC721Receiver, Pausable {
  
  // maximum alpha score for a Guard
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event PlayerClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event GuardClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Squuid NFT contract
  Squuid squuid;
  // reference to the $SQUID contract for minting $SQUID earnings
  SQUID squid;

  // maps tokenId to stake
  mapping(uint256 => Stake) public arena; 
  // maps alpha to all Guard stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Guard in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $SQUID due for each alpha point staked
  uint256 public squidPerAlpha = 0; 

  // player earn 10000 $SQUID per day
  uint256 public constant DAILY_SQUID_RATE = 5000 ether;
  // player must have 2 days worth of $SQUID to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // wolves take a 20% tax on all $SQUID claimed
  uint256 public constant SQUID_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $SQUID earned through staking
  uint256 public constant MAXIMUM_GLOBAL_SQUID = 6000000000 ether;

  // amount of $SQUID earned so far
  uint256 public totalSquidEarned;
  // number of Player staked in the Arena
  uint256 public totalPlayerStaked;
  // the last time $SQUID was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $SQUID
  bool public rescueEnabled = false;

  /**
   * @param _squuid reference to the Squuid NFT contract
   * @param _squid reference to the $SQUID token
   */
  constructor(address _squuid, address _squid) { 
    squuid = Squuid(_squuid);
    squid = SQUID(_squid);
  }

  /** STAKING */

  /**
   * adds Player and Wolves to the Arena and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Player and Wolves to stake
   */
  function addManyToArenaAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(squuid), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(squuid)) { // dont do this step if its a mint + stake
        require(squuid.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        squuid.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isPlayer(tokenIds[i])) 
        _addPlayerToArena(account, tokenIds[i]);
      else 
        _addGuardToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Player to the Arena
   * @param account the address of the staker
   * @param tokenId the ID of the Player to add to the Arena
   */
  function _addPlayerToArena(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    arena[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalPlayerStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Guard to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Guard to add to the Pack
   */
  function _addGuardToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForGuard(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the guard in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(squidPerAlpha)
    })); // Add the guard to the Pack
    emit TokenStaked(account, tokenId, squidPerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $SQUID earnings and optionally unstake tokens from the Arena / Pack
   * to unstake a Player it will require it has 2 days worth of $SQUID unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromArenaAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isPlayer(tokenIds[i]))
        owed += _claimPlayerFromArena(tokenIds[i], unstake);
      else
        owed += _claimGuardFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    squid.mint(_msgSender(), owed);
  }

  /**
   * realize $SQUID earnings for a single Player and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Wolves
   * if unstaking, there is a 50% chance all $SQUID is stolen
   * @param tokenId the ID of the Player to claim earnings from
   * @param unstake whether or not to unstake the Player
   * @return owed - the amount of $SQUID earned
   */
  function _claimPlayerFromArena(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = arena[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S SQUID");
    if (totalSquidEarned < MAXIMUM_GLOBAL_SQUID) {
      owed = (block.timestamp - stake.value) * DAILY_SQUID_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $SQUID production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_SQUID_RATE / 1 days; // stop earning additional $SQUID if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $SQUID stolen
        _payGuardTax(owed);
        owed = 0;
      }
      delete arena[tokenId];
      squuid.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Player
      totalPlayerStaked -= 1;
    } else {
      _payGuardTax(owed * SQUID_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked wolves
      owed = owed * (100 - SQUID_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Player owner
      arena[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit PlayerClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $SQUID earnings for a single Guard and optionally unstake it
   * Wolves earn $SQUID proportional to their Alpha rank
   * @param tokenId the ID of the Guard to claim earnings from
   * @param unstake whether or not to unstake the Guard
   * @return owed - the amount of $SQUID earned
   */
  function _claimGuardFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(squuid.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForGuard(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (squidPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Guard to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
      squuid.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Guard
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(squidPerAlpha)
      }); // reset stake
    }
    emit GuardClaimed(tokenId, owed, unstake);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 alpha;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isPlayer(tokenId)) {
        stake = arena[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete arena[tokenId];
        squuid.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Player
        totalPlayerStaked -= 1;
        emit PlayerClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForGuard(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Guard to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        squuid.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Guard
        emit GuardClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $SQUID to claimable pot for the Pack
   * @param amount $SQUID to add to the pot
   */
  function _payGuardTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked wolves
      unaccountedRewards += amount; // keep track of $SQUID due to wolves
      return;
    }
    // makes sure to include any unaccounted $SQUID 
    squidPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $SQUID earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalSquidEarned < MAXIMUM_GLOBAL_SQUID) {
      totalSquidEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalPlayerStaked
        * DAILY_SQUID_RATE / 1 days; 
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
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * checks if a token is a Player
   * @param tokenId the ID of the token to check
   * @return player - whether or not a token is a Player
   */
  function isPlayer(uint256 tokenId) public view returns (bool player) {
    (player, , , , , , , , , ) = squuid.tokenTraits(tokenId);
  }

  /**
   * gets the alpha score for a Guard
   * @param tokenId the ID of the Guard to get the alpha score for
   * @return the alpha score of the Guard (5-8)
   */
  function _alphaForGuard(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 alphaIndex) = squuid.tokenTraits(tokenId);
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * chooses a random Guard thief when a newly minted token is stolen
   * @param seed a random value to choose a Guard from
   * @return the owner of the randomly selected Guard thief
   */
  function randomGuardOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Wolves with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Guard with that alpha score
      return pack[i][seed % pack[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Arena directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}