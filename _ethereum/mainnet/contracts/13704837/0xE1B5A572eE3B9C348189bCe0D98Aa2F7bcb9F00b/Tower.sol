// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IWnDGame.sol";
import "./IWnD.sol";
import "./IGP.sol";
import "./ITower.sol";
import "./ISacrificialAlter.sol";
import "./console.sol";

contract Tower is ITower, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  
  // maximum rank for a Wizard/Dragon
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  struct Stats {
    uint16 numWizardsStaked;
    uint16 numDragonsStaked;
    uint16 totalRankStaked;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event WizardClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event DragonClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the WnD NFT contract
  IWnD public wndNFT;
  // reference to the WnD NFT contract
  IWnDGame public wndGame;
  // reference to the $GP contract for minting $GP earnings
  IGP public gpToken;

  // maps tokenId to stake
  mapping(uint256 => Stake) public tower; 
  // maps rank to all Dragon staked with that rank
  mapping(uint256 => Stake[]) public flight; 
  // tracks location of each Dragon in Flight
  mapping(uint256 => uint256) public flightIndices; 
  // any rewards distributed when no dragons are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $GP due for each rank point staked
  uint256 public gpPerRank = 0; 

  // wizards earn 12000 $GP per day
  uint256 public constant DAILY_GP_RATE = 12000 ether;
  // wizards must have 2 days worth of $GP to unstake or else they're still guarding the tower
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // dragons take a 20% tax on all $GP claimed
  uint256 public constant GP_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $GP earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GP = 2880000000 ether;
  uint256 public treasureChestTypeId;

  // amount of $GP earned so far
  uint256 public totalGPEarned;
  // the last time $GP was claimed
  uint256 public lastClaimTimestamp;
  Stats public stats;

  // emergency rescue to allow unstaking without any checks but without $GP
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(wndNFT) != address(0) && address(gpToken) != address(0) 
        && address(wndGame) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _wndNFT, address _gp, address _wndGame) external onlyOwner {
    wndNFT = IWnD(_wndNFT);
    gpToken = IGP(_gp);
    wndGame = IWnDGame(_wndGame);
  }

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  /** STAKING */

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToTowerAndFlight(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(wndGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(wndGame)) { // dont do this step if its a mint + stake
        require(wndNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        wndNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isWizard(tokenIds[i])) 
        _addWizardToTower(account, tokenIds[i]);
      else 
        _addDragonToFlight(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Wizard to the Tower
   * @param account the address of the staker
   * @param tokenId the ID of the Wizard to add to the Tower
   */
  function _addWizardToTower(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    tower[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    stats.numWizardsStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Dragon to the Flight
   * @param account the address of the staker
   * @param tokenId the ID of the Dragon to add to the Flight
   */
  function _addDragonToFlight(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDragon(tokenId);
    stats.totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    flightIndices[tokenId] = flight[rank].length; // Store the location of the dragon in the Flight
    flight[rank].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(gpPerRank)
    })); // Add the dragon to the Flight
    stats.numDragonsStaked += 1;
    emit TokenStaked(account, tokenId, gpPerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GP earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $GP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromTowerAndFlight(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(wndGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isWizard(tokenIds[i])) {
        owed += _claimWizardFromTower(tokenIds[i], unstake);
      }
      else {
        owed += _claimDragonFromFlight(tokenIds[i], unstake);
      }
    }
    gpToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    gpToken.mint(_msgSender(), owed);
  }

  /**
   * realize $GP earnings for a single Wizard and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Dragons
   * if unstaking, there is a 50% chance all $GP is stolen
   * @param tokenId the ID of the Wizards to claim earnings from
   * @param unstake whether or not to unstake the Wizards
   * @return owed - the amount of $GP earned
   */
  function _claimWizardFromTower(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = tower[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Still guarding the tower");
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
      owed = (block.timestamp - stake.value) * DAILY_GP_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GP production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_GP_RATE / 1 days; // stop earning additional $GP if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $GP stolen
        _payDragonTax(owed);
        owed = 0;
      }
      delete tower[tokenId];
      stats.numWizardsStaked -= 1;
      // Always transfer last to guard against reentrance
      wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Wizard
    } else {
      _payDragonTax(owed * GP_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked dragons
      owed = owed * (100 - GP_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Wizard owner
      tower[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit WizardClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $GP earnings for a single Dragon and optionally unstake it
   * Dragons earn $GP proportional to their rank
   * @param tokenId the ID of the Dragon to claim earnings from
   * @param unstake whether or not to unstake the Dragon
   * @return owed - the amount of $GP earned
   */
  function _claimDragonFromFlight(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(wndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForDragon(tokenId);
    Stake memory stake = flight[rank][flightIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = (rank) * (gpPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      stats.totalRankStaked -= rank; // Remove rank from total staked
      stats.numDragonsStaked -= 1;
      Stake memory lastStake = flight[rank][flight[rank].length - 1];
      flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
      flightIndices[lastStake.tokenId] = flightIndices[tokenId];
      flight[rank].pop(); // Remove duplicate
      delete flightIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Dragon
    } else {
      flight[rank][flightIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(gpPerRank)
      }); // reset stake
    }
    emit DragonClaimed(tokenId, owed, unstake);
  }
  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isWizard(tokenId)) {
        stake = tower[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete tower[tokenId];
        stats.numWizardsStaked -= 1;
        wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Wizards
        emit WizardClaimed(tokenId, 0, true);
      } else {
        rank = _rankForDragon(tokenId);
        stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        stats.totalRankStaked -= rank; // Remove Rank from total staked
        stats.numDragonsStaked -= 1;
        lastStake = flight[rank][flight[rank].length - 1];
        flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
        flightIndices[lastStake.tokenId] = flightIndices[tokenId];
        flight[rank].pop(); // Remove duplicate
        delete flightIndices[tokenId]; // Delete old mapping
        wndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Dragon
        emit DragonClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $GP to claimable pot for the Flight
   * @param amount $GP to add to the pot
   */
  function _payDragonTax(uint256 amount) internal {
    if (stats.totalRankStaked == 0) { // if there's no staked dragons
      unaccountedRewards += amount; // keep track of $GP due to dragons
      return;
    }
    // makes sure to include any unaccounted $GP 
    gpPerRank += (amount + unaccountedRewards) / stats.totalRankStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GP earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
      totalGPEarned += 
        (block.timestamp - lastClaimTimestamp)
        * stats.numWizardsStaked
        * DAILY_GP_RATE / 1 days; 
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
   * checks if a token is a Wizards
   * @param tokenId the ID of the token to check
   * @return wizard - whether or not a token is a Wizards
   */
  function isWizard(uint256 tokenId) public view returns (bool wizard) {
    (wizard, , , , , , , , , ) = wndNFT.tokenTraits(tokenId);
  }

  /**
   * gets the rank score for a Dragon
   * @param tokenId the ID of the Dragon to get the rank score for
   * @return the rank score of the Dragon (5-8)
   */
  function _rankForDragon(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 rankIndex) = wndNFT.tokenTraits(tokenId);
    return MAX_RANK - rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Dragon thief when a newly minted token is stolen
   * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
  function randomDragonOwner(uint256 seed) external view override returns (address) {
    if (stats.totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % stats.totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Dragons with the same rank score
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += flight[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Dragon with that rank score
      return flight[i][seed % flight[i].length].owner;
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
      require(from == address(0x0), "Cannot send to Tower directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}