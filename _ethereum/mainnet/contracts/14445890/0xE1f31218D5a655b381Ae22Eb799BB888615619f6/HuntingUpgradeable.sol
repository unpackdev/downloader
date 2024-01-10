// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./InterfacesMigrated.sol";


contract HuntingUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

  struct StakeFreak {
    uint256 tokenId;
    uint256 lastClaimTime;
    address owner;
    uint256 species;
    uint256 ffIndex;
  }

  struct StakeCelestial {
    uint256 tokenId;
    address owner;
    uint256 value;
  }

  struct Epoch {
    uint256 favoredFreak;
    uint256 epochStartTime;
  }

  struct PoolConfig {
    uint256 guildSize;
    uint256 rate;
    uint256 minToExit;
  }


/*///////////////////////////////////////////////////////////////
                    Global STATE
   //////////////////////////////////////////////////////////////*/

  // reference to the FnG NFT contract
  IFnG public fngNFT;
  // reference to the $FBX contract for minting $FBX earnings
  IFBX public fbx;
  // maps tokenId to stake observatory
  mapping(uint256 => StakeCelestial) private observatory;
  // maps pool id to mapping of address to deposits
  mapping(uint256 => mapping(address => EnumerableSetUpgradeable.UintSet)) private _deposits;
  // maps pool id to mapping of token id to staked freak struct
  mapping(uint256 => mapping(uint256 => StakeFreak)) private stakingPools;
  // maps pool id to pool config
  mapping(uint256 => PoolConfig) public _poolConfig;
  // maps pool id to amount of freaks staked
  mapping(uint256 => uint256) private freaksStaked;
  // maps pool id to epoch struct
  mapping(uint256 => Epoch[]) private favors;
  // any rewards distributed when no celestials are staked
  uint256 private unaccountedRewards;
  // amount of $FBX earned so far
  uint256 public totalFBXEarned;
  // timestamp of last epcoh change
  uint256 private lastEpoch;
  // number of celestials staked at a give time
  uint256 public cCounter;
  // unclaimed FBX pool for hunting observatory
  uint256 public fbxPerCelestial;
  // emergency rescue to allow unstaking without any checks but without $FBX
  bool public rescueEnabled;


  /*///////////////////////////////////////////////////////////////
                    INITIALIZER 
    //////////////////////////////////////////////////////////////*/


  function initialize(address _fng, address _fbx) public changeFFEpoch initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    fngNFT = IFnG(_fng);
    fbx = IFBX(_fbx);
    _pause();
    cCounter = 0;
    _poolConfig[0] = PoolConfig(1, 200 ether, 200 ether);
    _poolConfig[1] = PoolConfig(3, 300 ether, 1800 ether);
    _poolConfig[2] = PoolConfig(5, 400 ether, 6000 ether);
    freaksStaked[0] = 0;
    freaksStaked[1] = 0;
    freaksStaked[2] = 0;
    rescueEnabled = false;
    unaccountedRewards = 0;
  }

  function _authorizeUpgrade(address) internal onlyOwner override {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier changeFFEpoch() {
    if (block.timestamp - lastEpoch >= 72 hours) {
      uint256 rand = _rand(msg.sender);
      for (uint256 i = 0; i < 3; i++) {
        uint256 favoredFreak = (rand % 3) + 1;
        Epoch memory epoch = Epoch(favoredFreak, block.timestamp);
        favors[i].push(epoch);
        rand = uint256(keccak256(abi.encodePacked(msg.sender, rand)));
      }
      lastEpoch = block.timestamp;
    }
    _;
  }



  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // returns config for specific pool
  function getPoolConfig(uint256 pool) external view returns (PoolConfig memory) {
    require(pool < 3, "pool not found");
    return _poolConfig[pool];
  }

  // returns total freaks staked in specific pool
  function getStakedFreaks(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return freaksStaked[pool];
  }

  // returns deposited tokens of an address for each hunting ground and observatory
  function depositsOf(address account)
    external
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    return (
      _deposits[0][account].values(),
      _deposits[1][account].values(),
      _deposits[2][account].values(),
      _deposits[3][account].values()
    );
  }

  // returns rewards for freaks currently staked in specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function calculateFBXRewards(uint256[] memory tokenIds, uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
    }
    return rewards;
  }

  // returns rewards for celestials currently staked in hunting observatory
  function calculateCelestialsRewards(uint256[] calldata tokenIds) external view returns (uint256 rewards) {
    rewards = 0;
    for (uint256 i; i < tokenIds.length; i++) {
      rewards += _calculateCelestialRewards(tokenIds[i]);
    }
    return rewards;
  }

  // returns current favored freak for specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function getFavoredFreak(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return favors[pool][favors[pool].length - 1].favoredFreak;
  }

  // returns list of all favored freaks of a specific pool since genesis
  function getFavoredFreaks(uint256 pool) external view returns (Epoch[] memory) {
    require(pool < 3, "pool not found");
    return favors[pool];
  }

  // emergency rescue function to transfer tokens from contract to owner based on specific pool
  function rescue(uint256[] calldata tokenIds, uint256 pool) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    require(pool <= 3, "Pool doesn't exist");
    if (pool == 3) {
      //observatory
      for (uint256 i = 0; i < tokenIds.length; i++) {
        require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
        delete observatory[tokenIds[i]];
        _deposits[pool][msg.sender].remove(tokenIds[i]);
        cCounter -= 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      }
    } else {
      uint256 newTotal = 0;
      for (uint256 l = 0; l < tokenIds.length; l++) {
        require(stakingPools[pool][tokenIds[l]].owner == msg.sender, "You don't own this token ser");
        delete stakingPools[pool][tokenIds[l]];
        _deposits[pool][msg.sender].remove(tokenIds[l]);
        newTotal += 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[l]);
      }
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
  }

  /*///////////////////////////////////////////////////////////////
                    STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function observe(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(!fngNFT.isFreak(tokenIds[i]), "CELESTIALS ONLY!!! You are not worthy FREAK!");
      observatory[tokenIds[i]] = StakeCelestial({tokenId: tokenIds[i], owner: msg.sender, value: fbxPerCelestial});
      _deposits[3][msg.sender].add(tokenIds[i]);
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      cCounter += 1;
    }
  }

  function observeFromMigration(address owner, uint256[] calldata tokenIds) external changeFFEpoch nonReentrant whenNotPaused {
    require(address(fngNFT) == msg.sender, "you aren't FnG");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == address(this), "token not transfered");
      require(!fngNFT.isFreak(tokenIds[i]), "CELESTIALS ONLY!!! You are not worthy FREAK!");
      observatory[tokenIds[i]] = StakeCelestial({tokenId: tokenIds[i], owner: owner, value: fbxPerCelestial});
      _deposits[3][owner].add(tokenIds[i]);
      // fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      cCounter += 1;
    }
  }

  function hunt(uint256[] calldata tokenIds, uint256 pool) external changeFFEpoch nonReentrant whenNotPaused {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length % _poolConfig[pool].guildSize == 0, "incorrect amount of freaks");
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(fngNFT.isFreak(tokenIds[i]), "Can't get freaky without any freaks ser");
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
      _deposits[pool][msg.sender].add(tokenIds[i]);
      newTotal += 1;
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
    freaksStaked[pool] = freaksStaked[pool] + newTotal;
  }

  function huntFromMigration(address owner, uint256[] calldata tokenIds, uint256 pool) external changeFFEpoch nonReentrant whenNotPaused {
    require(msg.sender == address(fngNFT), "you aren't FnG");
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length % _poolConfig[pool].guildSize == 0, "incorrect amount of freaks");
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == address(this), "token not transfered");
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: owner,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
      _deposits[pool][owner].add(tokenIds[i]);
      newTotal += 1;
    }
    freaksStaked[pool] = freaksStaked[pool] + newTotal;
  }

  /*///////////////////////////////////////////////////////////////
                    CLAIM/UNSTAKE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // unstake or claim from multiple freaks in a specific pool
  function claimUnstake(
    uint256[] calldata tokenIds,
    uint256 pool,
    bool collectTax
  ) external changeFFEpoch nonReentrant {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length != 0, "can't claim no tokens");
    uint256 rewards = 0;
    uint256 rewardsPerGroup = 0;
    require(tokenIds.length % _poolConfig[pool].guildSize == 0);
    if (collectTax == true) {
      rewards = _calculateManyFreakRewards(tokenIds, pool, false);
      rewardsPerGroup = rewards / (tokenIds.length / _poolConfig[pool].guildSize);
      require(rewardsPerGroup >= _poolConfig[pool].minToExit, "Not enough $FBX earned per group");
      _claimWithTax(rewards, pool, tokenIds);
    } else {
      rewards = _calculateManyFreakRewards(tokenIds, pool, true);
      rewardsPerGroup = rewards / (tokenIds.length / _poolConfig[pool].guildSize);
      _claimEvadeTax(rewards, rewardsPerGroup, pool, tokenIds);
    }
  }

  function unobserve(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant {
    uint256 newCounter = 0;
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      if (fbxPerCelestial != 0) {
        rewards += fbxPerCelestial - observatory[tokenIds[i]].value;
      } else {
        rewards += 0;
      }
      delete observatory[tokenIds[i]];
      _deposits[3][msg.sender].remove(tokenIds[i]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      newCounter += 1;
    }
    fbx.mint(msg.sender, rewards);
    totalFBXEarned += rewards;
    cCounter = cCounter - newCounter;
  }

  /*///////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _calculateManyFreakRewards(uint256[] memory tokenIds, uint256 pool, bool unstake) internal returns (uint256 owed) {
    uint256 rewards = 0;
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(stakingPools[pool][tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
      newTotal += 1;
    }
    if (unstake == true) {
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
    return rewards;
  }

  function _calculateCelestialRewards(uint256 tokenId) internal view returns (uint256 reward) {
    if (fbxPerCelestial != 0) {
      reward = fbxPerCelestial - observatory[tokenId].value;
    }
    if (fbxPerCelestial == 0) {
      reward = 0;
    }
    return reward;
  }

  function _calculateSingleFreakRewards(
    uint256 tokenId,
    uint256 pool,
    uint256 rate
  ) internal view returns (uint256 owed) {
    uint256 timestamp = stakingPools[pool][tokenId].lastClaimTime;
    if (timestamp == 0) {
      return 0;
    }
    uint256 species = stakingPools[pool][tokenId].species;
    uint256 duration = block.timestamp - timestamp;
    uint256 favoredDuration = 0;
    for (uint256 j = stakingPools[pool][tokenId].ffIndex; j < favors[pool].length; j++) {
      uint256 startTime;
      if (j == stakingPools[pool][tokenId].ffIndex) {
        startTime = stakingPools[pool][tokenId].lastClaimTime;
      } else {
        startTime = favors[pool][j].epochStartTime;
      }
      if (favors[pool][j].favoredFreak == species) {
        uint256 epochEndTime;
        if (favors[pool].length == j + 1) {
          epochEndTime = block.timestamp;
        } else {
          epochEndTime = favors[pool][j + 1].epochStartTime;
        }
        favoredDuration += epochEndTime - startTime;
      }
    }
    uint256 ffOwed = ((favoredDuration * (rate + 20 ether)) / 1 days);
    uint256 baseOwed = 0;
    if (duration - favoredDuration != 0) {
      baseOwed = (((duration - favoredDuration) * rate) / 1 days);
    }
    owed = ffOwed + baseOwed;
    return owed;
  }

  function _claimWithTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 celestialRewards;
    celestialRewards = rewards / 5;
    if (cCounter == 0) {
      unaccountedRewards += (celestialRewards);
      rewards = rewards - celestialRewards;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    } else {
      fbxPerCelestial += (unaccountedRewards + celestialRewards) / cCounter;
      rewards = rewards - celestialRewards;
      unaccountedRewards = 0;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 i; i < tokenIds.length; i++) {
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
    }
  }

  function _claimEvadeTax(
    uint256 rewards,
    uint256 rewardsPerGroup,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 rNum = _rand(msg.sender) % 100;
    if (rNum < 33 || rewardsPerGroup < _poolConfig[pool].minToExit) {
      if (cCounter == 0) {
        unaccountedRewards += rewards;
      } else {
        fbxPerCelestial += (unaccountedRewards + rewards) / cCounter;
        unaccountedRewards = 0;
      }
    } else {
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 j; j < tokenIds.length; j++) {
      _deposits[pool][msg.sender].remove(tokenIds[j]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[j]);
      delete stakingPools[pool][tokenIds[j]]; 
    }
  }

  function _rand(address acc) internal view returns (uint256) {
    bytes32 _entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, _entropySauce)));
  }

  /*///////////////////////////////////////////////////////////////
                   ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function setContracts(address _fngNFT, address _fbx) external onlyOwner {
    fngNFT = IFnG(_fngNFT);
    fbx = IFBX(_fbx);
  }

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
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * backup favored freak epoch changing function
   * in case it isn't triggered by claim/unstake function (unlikely)
   */
  function backupEpochSet() public changeFFEpoch onlyOwner {}

  /**
   * manually set rates for each pool
   */
  function setRates(
    uint256 _enclaveRate,
    uint256 _summitRate,
    uint256 _anoRate
  ) external onlyOwner {
    _poolConfig[0].rate = _enclaveRate;
    _poolConfig[1].rate = _summitRate;
    _poolConfig[2].rate = _anoRate;
  }

  /**
   * manually set minimum FBX required to exit each pool
   */
  function setMinExits(
    uint256 _minExitEnclave,
    uint256 _minExitSummit,
    uint256 _minExitAno
  ) external onlyOwner {
    _poolConfig[0].minToExit = _minExitEnclave;
    _poolConfig[1].minToExit = _minExitSummit;
    _poolConfig[2].minToExit = _minExitAno;
  }


}
