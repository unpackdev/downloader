// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IWnDGame.sol";
import "./ITrainingGrounds.sol";
import "./ITraits.sol";
import "./IGP.sol";
import "./IWnD.sol";
import "./ISacrificialAlter.sol";


contract WnDGameTG is IWnDGame, Ownable, ReentrancyGuard, Pausable {

  struct MintCommit {
    address recipient;
    bool stake;
    uint16 amount;
  }

  struct TrainingCommit {
    address tokenOwner;
    uint16 tokenId;
    bool isAdding; // If false, the commit is for claiming rewards
    bool isUnstaking; // If !isAdding, this will determine if user is unstaking
    bool isTraining; // If !isAdding, this will define where the staked token is (only necessary for wizards)
  }

  uint256 public constant TREASURE_CHEST = 5;
  // max $GP cost 
  uint256 private maxGpCost = 72000 ether;

  /** =========== MINTING COMMIT AND REVEAL VARIABLES =========== */
  // commitId -> array of all pending commits
  mapping(uint16 => MintCommit[]) private commitQueueMints;
  // Track when a commitId started accepting commits
  mapping(uint16 => uint256) private commitIdStartTimeMints;
  mapping(address => uint16) private pendingMintCommitsForAddr;
  // Tracks the current commitId batch to put new commits into
  uint16 private _commitIdCurMints = 1;
  // tracks the oldest commitId that has commits needing to be revealed
  uint16 private _commitIdPendingMints = 0;
  /** =========== TRAINING COMMIT AND REVEAL VARIABLES =========== */
  // commitId -> array of all pending commits
  mapping(uint16 => TrainingCommit[]) private commitQueueTraining;
  // Track when a commitId started accepting commits
  mapping(uint16 => uint256) private commitIdStartTimeTraining;
  mapping(address => uint16) private pendingTrainingCommitsForAddr;
  mapping(uint256 => bool) private tokenHasPendingCommit;
  // Tracks the current commitId batch to put new commits into
  uint16 private _commitIdCurTraining = 1;
  // tracks the oldest commitId that has commits needing to be revealed
  uint16 private _commitIdPendingTraining = 0;

  // Time from starting a commit batch to allow new commits to enter
  uint64 private timePerCommitBatch = 5 minutes;
  // Time from starting a commit batch to allow users to reveal these in exchange for $GP
  uint64 private timeToAllowArb = 1 hours;
  uint16 private pendingMintAmt;
  bool public allowCommits = true;

  uint256 private revealRewardAmt = 36000 ether;
  uint256 private stakingCost = 8000 ether;

  // reference to the TrainingGrounds
  ITrainingGrounds public trainingGrounds;
  // reference to $GP for burning on mint
  IGP public gpToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  IWnD public wndNFT;
  // reference to alter collection
  ISacrificialAlter public alter;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(gpToken) != address(0) && address(traits) != address(0) 
        && address(wndNFT) != address(0) && address(alter) != address(0)
         && address(trainingGrounds) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _gp, address _traits, address _wnd, address _alter, address _trainingGrounds) external onlyOwner {
    gpToken = IGP(_gp);
    traits = ITraits(_traits);
    wndNFT = IWnD(_wnd);
    alter = ISacrificialAlter(_alter);
    trainingGrounds = ITrainingGrounds(_trainingGrounds);
  }

  /** EXTERNAL */

  function getPendingMintCommits(address addr) external view returns (uint16) {
    return pendingMintCommitsForAddr[addr];
  }
  function getPendingTrainingCommits(address addr) external view returns (uint16) {
    return pendingTrainingCommitsForAddr[addr];
  }
  function isTokenPendingReveal(uint256 tokenId) external view returns (bool) {
    return tokenHasPendingCommit[tokenId];
  }
  function hasStaleMintCommit() external view returns (bool) {
    uint16 pendingId = _commitIdPendingMints;
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[pendingId].length == 0 && pendingId < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      pendingId += 1;
    }
    return commitIdStartTimeMints[pendingId] < block.timestamp - timeToAllowArb && commitQueueMints[pendingId].length > 0;
  }
  function hasStaleTrainingCommit() external view returns (bool) {
    uint16 pendingId = _commitIdPendingTraining;
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[pendingId].length == 0 && pendingId < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      pendingId += 1;
    }
    return commitIdStartTimeTraining[pendingId] < block.timestamp - timeToAllowArb && commitQueueTraining[pendingId].length > 0;
  }

  /** Allow users to reveal the oldest commit for GP. Mints commits must be stale to be able to be revealed this way */
  function revealOldestMint() external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitIdStartTimeMints[_commitIdPendingMints] < block.timestamp - timeToAllowArb && commitQueueMints[_commitIdPendingMints].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    MintCommit memory commit = commitQueueMints[_commitIdPendingMints][commitQueueMints[_commitIdPendingMints].length - 1];
    commitQueueMints[_commitIdPendingMints].pop();
    revealMint(commit);
    gpToken.mint(_msgSender(), revealRewardAmt * commit.amount);
  }

  /** Allow users to reveal the oldest commit for GP. Mints commits must be stale to be able to be revealed this way */
  function skipOldestMint() external onlyOwner {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitQueueMints[_commitIdPendingMints].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    commitQueueMints[_commitIdPendingMints].pop();
    // Do not reveal the commit, only pop it from the queue and move on.
    // revealMint(commit);
  }

  function revealOldestTraining() external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitIdStartTimeTraining[_commitIdPendingTraining] < block.timestamp - timeToAllowArb && commitQueueTraining[_commitIdPendingTraining].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
    commitQueueTraining[_commitIdPendingTraining].pop();
    revealTraining(commit);
    gpToken.mint(_msgSender(), revealRewardAmt);
  }

  function skipOldestTraining() external onlyOwner {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitQueueTraining[_commitIdPendingTraining].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
    commitQueueTraining[_commitIdPendingTraining].pop();
    // Do not reveal the commit, only pop it from the queue and move on.
    // revealTraining(commit);
    tokenHasPendingCommit[commit.tokenId] = false;
  }

  /** Initiate the start of a mint. This action burns $GP, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    if(commitIdStartTimeMints[_commitIdCurMints] == 0) {
      commitIdStartTimeMints[_commitIdCurMints] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeMints[_commitIdCurMints] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurMints += 1;
      commitIdStartTimeMints[_commitIdCurMints] = block.timestamp;
    }

    // Add this mint request to the commit queue for the current commitId
    uint256 totalGpCost = 0;
    // Loop through the amount of 
    for (uint i = 1; i <= amount; i++) {
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueMints[_commitIdCurMints].push(MintCommit(_msgSender(), stake, 1));
      totalGpCost += mintCost(minted + pendingMintAmt + i, maxTokens);
    }
    if (totalGpCost > 0) {
      gpToken.burn(_msgSender(), totalGpCost);
      gpToken.updateOriginAccess();
    }
    uint16 amt = uint16(amount);
    pendingMintCommitsForAddr[_msgSender()] += amt;
    pendingMintAmt += amt;

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    if(commitIdStartTimeMints[_commitIdPendingMints] < block.timestamp - timePerCommitBatch && commitQueueMints[_commitIdPendingMints].length > 0) {
      // If the pending batch is old enough to be revealed and has stuff in it, mine the number that was added to the queue.
      for (uint256 i = 0; i < amount; i++) {
        // First iteration is guaranteed to have 1 commit to mine, so we can always retroactively check that we can continue to reveal after
        MintCommit memory commit = commitQueueMints[_commitIdPendingMints][commitQueueMints[_commitIdPendingMints].length - 1];
        commitQueueMints[_commitIdPendingMints].pop();
        revealMint(commit);
        // Check to see if we are able to continue mining commits
        if(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
          _commitIdPendingMints += 1;
          if(commitIdStartTimeMints[_commitIdPendingMints] > block.timestamp - timePerCommitBatch 
            || commitQueueMints[_commitIdPendingMints].length == 0
            || _commitIdPendingMints == _commitIdCurMints)
          {
            // If there are no more commits to reveal, exit
            break;
          }
        }
      }
    }
  }

  function revealMint(MintCommit memory commit) internal {
    uint16 minted = wndNFT.minted();
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint16[] memory tokenIdsToStake = new uint16[](commit.amount);
    uint256 seed = uint256(keccak256(abi.encode(commit.recipient, minted, commitIdStartTimeMints[_commitIdPendingMints])));
    for (uint k = 0; k < commit.amount; k++) {
      minted++;
      // scramble the random so the steal / treasure mechanic are different per mint
      seed = uint256(keccak256(abi.encode(seed, commit.recipient)));
      address recipient = selectRecipient(seed, commit.recipient);
      if(recipient != commit.recipient && alter.balanceOf(commit.recipient, TREASURE_CHEST) > 0) {
        // If the mint is going to be stolen, there's a 50% chance 
        //  a dragon will prefer a treasure chest over it
        if(seed & 1 == 1) {
          alter.safeTransferFrom(commit.recipient, recipient, TREASURE_CHEST, 1, "");
          recipient = commit.recipient;
        }
      }
      tokenIds[k] = minted;
      if (!commit.stake || recipient != commit.recipient) {
        wndNFT.mint(recipient, seed);
      } else {
        wndNFT.mint(address(trainingGrounds), seed);
        tokenIdsToStake[k] = minted;
      }
    }
    wndNFT.updateOriginAccess(tokenIds);
    // mints are revealed 1 at a time. Because of this, we only need to check if the first tokenId is stolen
    // Don't call add many if there is no token to add.
    if(commit.stake && tokenIdsToStake[0] != 0) {
      trainingGrounds.addManyToTowerAndFlight(commit.recipient, tokenIdsToStake);
    }
    pendingMintCommitsForAddr[commit.recipient] -= commit.amount;
  }

  function addToTower(uint16[] calldata tokenIds) external whenNotPaused {
    require(_msgSender() == tx.origin, "Only EOA");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
    }
    trainingGrounds.addManyToTowerAndFlight(tx.origin, tokenIds);
  }

  function addToTrainingCommit(uint16[] calldata tokenIds) external whenNotPaused {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    if(commitIdStartTimeTraining[_commitIdCurTraining] == 0) {
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeTraining[_commitIdCurTraining] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurTraining += 1;
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }
    // Loop through the amount of tokens being added
    uint16 numDragons;
    for (uint i = 0; i < tokenIds.length; i++) {
      require(address(trainingGrounds) != wndNFT.ownerOf(tokenIds[i]), "token already staked");
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
      require(_msgSender() == wndNFT.ownerOf(tokenIds[i]), "not owner of token");
      if(!wndNFT.isWizard(tokenIds[i])) {
        numDragons += 1;
      }
      tokenHasPendingCommit[tokenIds[i]] = true;
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueTraining[_commitIdCurTraining].push(TrainingCommit(_msgSender(), tokenIds[i], true, false, true));
    }
    gpToken.burn(_msgSender(), stakingCost * (tokenIds.length - numDragons)); // Dragons are free to stake
    gpToken.updateOriginAccess();
    pendingTrainingCommitsForAddr[_msgSender()] += uint16(tokenIds.length);
    tryRevealTraining(tokenIds.length);
  }

  function claimTrainingsCommit(uint16[] calldata tokenIds, bool isUnstaking, bool isTraining) external whenNotPaused {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    if(commitIdStartTimeTraining[_commitIdCurTraining] == 0) {
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeTraining[_commitIdCurTraining] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurTraining += 1;
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }
    uint16 numDragons;
    // Loop through the amount of tokens being added
    for (uint i = 0; i < tokenIds.length; i++) {
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
      require(trainingGrounds.isTokenStaked(tokenIds[i], isTraining) && trainingGrounds.ownsToken(tokenIds[i])
      , "Token not in staking pool");
      if(isUnstaking) {
        if(wndNFT.isWizard(tokenIds[i])) {
          // Check to see if the wizard has earned enough to withdraw.
          // If emissions run out, allow them to attempt to withdraw anyways.
          if(isTraining) {
            require(trainingGrounds.curWhipsEmitted() >= 16000
              || trainingGrounds.calculateErcEmissionRewards(tokenIds[i]) > 0, "can't unstake wizard yet");
          }
          else {
            require(trainingGrounds.totalGPEarned() > 500000000 ether - 4000 ether
              || trainingGrounds.calculateGpRewards(tokenIds[i]) >= 4000 ether, "can't unstake wizard yet");
          }
        }
        else {
          numDragons += 1;
        }
      }
      tokenHasPendingCommit[tokenIds[i]] = true;
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueTraining[_commitIdCurTraining].push(TrainingCommit(_msgSender(), tokenIds[i], false, isUnstaking, isTraining));
    }
    if(isUnstaking) {
      gpToken.burn(_msgSender(), stakingCost * (tokenIds.length - numDragons)); // Dragons are free to stake
      gpToken.updateOriginAccess();
    }
    pendingTrainingCommitsForAddr[_msgSender()] += uint16(tokenIds.length);
    tryRevealTraining(tokenIds.length);
  }

  function tryRevealTraining(uint256 amount) internal {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    if(commitIdStartTimeTraining[_commitIdPendingTraining] < block.timestamp - timePerCommitBatch && commitQueueTraining[_commitIdPendingTraining].length > 0) {
      // If the pending batch is old enough to be revealed and has stuff in it, mine the number that was added to the queue.
      for (uint256 i = 0; i < amount; i++) {
        // First iteration is guaranteed to have 1 commit to mine, so we can always retroactively check that we can continue to reveal after
        TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
        commitQueueTraining[_commitIdPendingTraining].pop();
        revealTraining(commit);
        // Check to see if we are able to continue mining commits
        if(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
          _commitIdPendingTraining += 1;
          if(commitIdStartTimeTraining[_commitIdPendingTraining] > block.timestamp - timePerCommitBatch 
            || commitQueueTraining[_commitIdPendingTraining].length == 0
            || _commitIdPendingTraining == _commitIdCurTraining)
          {
            // If there are no more commits to reveal, exit
            break;
          }
        }
      }
    }
  }

  function revealTraining(TrainingCommit memory commit) internal {
    uint16[] memory idSingle = new uint16[](1);
    idSingle[0] = commit.tokenId;
    tokenHasPendingCommit[commit.tokenId] = false;
    if(commit.isAdding) {
      if(wndNFT.ownerOf(commit.tokenId) != commit.tokenOwner) {
        // The owner has transferred their token and can no longer be staked. We can simply skip this reveal.
        return;
      }
      if(wndNFT.isWizard(commit.tokenId)) {
        // Add to training since tower staking doesn't need C+R
        uint256 seed = random(commit.tokenId, commitIdStartTimeTraining[_commitIdPendingTraining], commit.tokenOwner);
        trainingGrounds.addManyToTrainingAndFlight(seed, commit.tokenOwner, idSingle);
      }
      else {
        // Dragons go to the tower but really they are in both pools. This just avoids the stealing logic.
        trainingGrounds.addManyToTowerAndFlight(commit.tokenOwner, idSingle);
      }
    }
    else {
      if(!trainingGrounds.isTokenStaked(commit.tokenId, commit.isTraining)) {
        // Skip reveals if the token has already been claimed since committing to this tx (like claiming multiple times unknowingly)
        return;
      }
      if(commit.isTraining) {
        uint256 seed = random(commit.tokenId, commitIdStartTimeTraining[_commitIdPendingTraining], commit.tokenOwner);
        trainingGrounds.claimManyFromTrainingAndFlight(seed, commit.tokenOwner, idSingle, commit.isUnstaking);
      }
      else {
        trainingGrounds.claimManyFromTowerAndFlight(commit.tokenOwner, idSingle, commit.isUnstaking);
      }
    }
    pendingTrainingCommitsForAddr[commit.tokenOwner] -= 1;
  }

  /** Deterministically random. This assumes the call was a part of commit+reveal design 
   * that disallowed the benefactor of this outcome to make this call */
  function random(uint16 tokenId, uint256 time, address owner) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      owner,
      tokenId,
      time
    )));
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens * 8 / 20) return 24000 ether;
    if (tokenId <= maxTokens * 11 / 20) return 36000 ether;
    if (tokenId <= maxTokens * 14 / 20) return 48000 ether;
    if (tokenId <= maxTokens * 17 / 20) return 60000 ether; 
    // if (tokenId > maxTokens * 17 / 20)
    return maxGpCost;
  }

  function makeTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    // $GP exchange amount handled within alter contract
    // Will fail if sender doesn't have enough $GP
    // Transfer does not need approved,
    //  as there is established trust between this contract and the alter contract 
    alter.mint(TREASURE_CHEST, qty, _msgSender());
  }

  function sellTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    // $GP exchange amount handled within alter contract
    alter.burn(TREASURE_CHEST, qty, _msgSender());
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed, address committer) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return committer; // top 10 bits haven't been used
    address thief = trainingGrounds.randomDragonOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return committer;
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxGpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxGpCost = _amount;
  }

  function setAllowCommits(bool allowed) external onlyOwner {
    allowCommits = allowed;
  }

  function setRevealRewardAmt(uint256 rewardAmt) external onlyOwner {
    revealRewardAmt = rewardAmt;
  }

  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been 
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}