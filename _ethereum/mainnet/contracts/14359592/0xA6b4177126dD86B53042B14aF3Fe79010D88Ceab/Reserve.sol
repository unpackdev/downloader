// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Receiver.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSet.sol";

import "./safari-erc721.sol";
import "./safari-erc20.sol";
import "./token-metadata.sol";

contract Reserve is UUPSUpgradeable, OwnableUpgradeable, IERC721Receiver, PausableUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event AnimalClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event PoacherClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event APRClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event RubyStolen(address owner, uint256 tokenId, uint256 value);


  // Animals earn 10000 $RUBY per day
  uint256 public constant DAILY_RUBY_RATE = 10000 ether;
  // Animals must have 2 days worth of $RUBY to unstake
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // Poachers take a 25% tax on all $RUBY claimed
  uint8 public constant RUBY_CLAIM_TAX_PERCENTAGE = 25;
  // there will only ever be (roughly) 2.4 billion $RUBY earned through staking
  uint256 public constant MAXIMUM_GLOBAL_RUBY = 5000000000 ether;


  // reference to the Safari Battle NFT contract
  SafariErc721 safari;

  // reference to the $RUBY contract for minting $RUBY earnings
  SafariErc20 ruby;
  

  // maps tokenId to stake
  mapping(uint256 => Stake) public animals; 
  // tokens ids of Animals deposited for each owner
  mapping(address => EnumerableSet.UintSet) private _animalDeposits;

  // maps alpha to list of Poachers with that alpha
  mapping(uint256 => Stake[]) public poachers; 
  // tracks location of each Poacher
  mapping(uint256 => uint256) public poacherIndices; 
  // tokens ids of Poachers deposited for each owner
  mapping(address => EnumerableSet.UintSet) private _poacherDeposits;

  // maps alpha to list of APRs with that alpha
  mapping(uint256 => Stake) public aprs; 
  // tokens ids of APRs deposited for each owner
  mapping(address => EnumerableSet.UintSet) private _aprDeposits;

  // contracts allowed to stake directly from minting
  mapping(address => bool) public minters;

  // any rewards distributed when no Poachers are staked
  uint40 public unaccountedRewards; 
  
  // total Poacher alpha scores staked
  uint24 public totalPoacherAlphaStaked; 
  
  // total APR alpha scores staked
  uint24 public totalAPRAlphaStaked; 
  
  // amount of $RUBY due for each Poacher alpha point staked
  uint40 public rubyPerPoacherAlpha; 

  // amount of $RUBY due for each APR alpha point staked
  uint40 public rubyPerAPRAlpha; 

  // amount of $RUBY earned so far
  uint40 public totalRubyEarned;

  // the last time $RUBY was claimed
  uint32 public lastClaimTimestamp;

  // number of Animals staked
  uint16 public totalAnimalsStaked;

  // number of APRs staked
  uint16 public totalAPRsStaked;

  // emergency rescue to allow unstaking without any checks but without $RUBY
  bool public rescueEnabled;



  /**
   * @param _safari reference to the Safari Battle NFT contract
   * @param _ruby reference to the $RUBY token
   */
  function initialize(address _safari, address _ruby) public initializer {
    __Ownable_init_unchained();
    __Pausable_init_unchained();

    safari = SafariErc721(_safari);
    ruby = SafariErc20(_ruby);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


  function setMinter(address _minter, bool enabled) external onlyOwner {
    minters[_minter] = enabled;
  }


  /** STAKING */

  /**
   * stake tokens
   * @param account the address of the staker
   * @param tokenIds the IDs of the NFTs to stake
   */
  function stakeMany(address account, uint16[] calldata tokenIds) external whenNotPaused _updateEarnings {
    require(minters[_msgSender()] || tx.origin == _msgSender(), "must be EOA or Minter");

    // if EOA then transfer tokens to Reserve
    if (_msgSender() == tx.origin) {
      safari.batchStake(account, tokenIds);
    }

    for (uint i = 0; i < tokenIds.length; i++) {
      if (isAnimal(tokenIds[i])) {
        _stakeAnimal(account, tokenIds[i]);
      } else if (isPoacher(tokenIds[i])) {
        _stakePoacher(account, tokenIds[i]);
      } else {
        _stakeAPR(account, tokenIds[i]);
      }
    }
  }

  /**
   * adds a single Animal to the Reserve
   * @param account the address of the staker
   * @param tokenId the ID of the Anial to stake
   */
  function _stakeAnimal(address account, uint256 tokenId) internal {
    animals[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    _animalDeposits[account].add(tokenId);
    totalAnimalsStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Poacher
   * @param account the address of the staker
   * @param tokenId the ID of the Poacher
   */
  function _stakePoacher(address account, uint256 tokenId) internal {
    uint8 alpha = _alphaForPoacher(tokenId);
    totalPoacherAlphaStaked += alpha;
    // Store the index of the Poacher
    poacherIndices[tokenId] = poachers[alpha].length;
    poachers[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(rubyPerPoacherAlpha)
    }));
    _poacherDeposits[account].add(tokenId);
    emit TokenStaked(account, tokenId, uint256(rubyPerPoacherAlpha) * 1 ether / 100);
  }

  function _stakeAPR(address account, uint256 tokenId) internal {
    aprs[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    _aprDeposits[account].add(tokenId);
    totalAPRsStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $RUBY earnings and optionally unstake tokens.
   * an Animal must have 20,000 RUBY accumulated to be unstaked
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimMany(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    require(tx.origin == _msgSender(), 'must be EOA');

    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isAnimal(tokenIds[i])) {
        owed += _claimAnimal(tokenIds[i], unstake);
      } else if (isPoacher(tokenIds[i])) {
        owed += _claimPoacher(tokenIds[i], unstake);
      } else {
        _claimAPR(tokenIds[i], unstake);
      }
    }
    if (owed == 0) return;
    ruby.mint(_msgSender(), owed * 1 ether);
  }

  /**
   * realize $RUBY earnings for a single Animal and optionally unstake it
   * if not unstaking, pay a 25% tax to the staked Poachers
   * if unstaking, there is a 50% chance all $RUBY is stolen
   * @param tokenId the ID of the Animal to claim earnings from
   * @param unstake whether or not to unstake the Animal
   * @return owed - the amount of $RUBY earned
   */
  function _claimAnimal(uint256 tokenId, bool unstake) internal returns (uint40 owed) {
    Stake memory stake = animals[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "not enough RUBY to unstake");
    if ((uint256(totalRubyEarned) * 1 ether) < MAXIMUM_GLOBAL_RUBY) {
      owed = uint40((block.timestamp - stake.value) * DAILY_RUBY_RATE / 1 ether / 1 days);
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $RUBY production stopped already
    } else {
      owed = uint40((lastClaimTimestamp - stake.value) * DAILY_RUBY_RATE / 1 ether / 1 days); // stop earning additional $RUBY if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of having $RUBY stolen
        uint8 percentProtected = _getPercentProtected(stake.owner);
	uint40 stolen = uint40(owed * (100 - percentProtected) / 100);
        _payPoacherTax(stolen);
        owed -= stolen;
	emit RubyStolen(stake.owner, tokenId, uint256(stolen) * 1 ether);
      }
      _animalDeposits[msg.sender].remove(tokenId);
      delete animals[tokenId];
      safari.transferFrom(address(this), _msgSender(), tokenId);
      totalAnimalsStaked -= 1;
    } else {
      _payPoacherTax(uint40(owed * RUBY_CLAIM_TAX_PERCENTAGE / 100));
      owed = owed * (100 - RUBY_CLAIM_TAX_PERCENTAGE) / 100;
      animals[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit AnimalClaimed(tokenId, uint256(owed) * 1 ether, unstake);
  }

  /**
   * realize $RUBY earnings for a single Poacher and optionally unstake it
   * Poachers earn $RUBY proportional to their Alpha rank
   * @param tokenId the ID of the Poacher to claim earnings from
   * @param unstake whether or not to unstake the Poacher
   * @return owed - the amount of $RUBY earned
   */
  function _claimPoacher(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(safari.ownerOf(tokenId) == address(this), "poacher is not staked");
    uint8 alpha = _alphaForPoacher(tokenId);
    Stake memory stake = poachers[alpha][poacherIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = uint40(alpha) * (rubyPerPoacherAlpha - stake.value) / 100; // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalPoacherAlphaStaked -= alpha; // Remove Alpha from total staked
      _poacherDeposits[msg.sender].remove(tokenId);
      Stake memory lastStake = poachers[alpha][poachers[alpha].length - 1];
      poachers[alpha][poacherIndices[tokenId]] = lastStake; // Shuffle last Poacher to current position
      poacherIndices[lastStake.tokenId] = poacherIndices[tokenId];
      poachers[alpha].pop(); // Remove duplicate
      delete poacherIndices[tokenId]; // Delete old mapping
      safari.transferFrom(address(this), _msgSender(), tokenId);
    } else {
      poachers[alpha][poacherIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(rubyPerPoacherAlpha)
      }); // reset stake
    }
    emit PoacherClaimed(tokenId, owed, unstake);
  }

  function _claimAPR(uint256 tokenId, bool unstake) internal {
    Stake memory stake = aprs[tokenId];
    require(safari.ownerOf(tokenId) == address(this), "apr is not staked");
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    if (unstake) {
      _aprDeposits[msg.sender].remove(tokenId);
      delete aprs[tokenId];
      safari.transferFrom(address(this), _msgSender(), tokenId);
      totalAPRsStaked -= 1;
    }
    emit APRClaimed(tokenId, 0, unstake);
  }

  function _getPercentProtected(address tokenOwner) internal view returns(uint8) {
    uint256 numAPRs = _aprDeposits[tokenOwner].length();
    if (numAPRs >= 5) {
      return 75;
    } else if (numAPRs >= 4) {
      return 60;
    } else if (numAPRs >= 3) {
      return 50;
    } else if (numAPRs >= 2) {
      return 25;
    } else if (numAPRs >= 1) {
      return 20;
    }
    return 0;
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
    uint8 alpha;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isAnimal(tokenId)) {
        stake = animals[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        _animalDeposits[msg.sender].remove(tokenId);
        safari.safeTransferFrom(address(this), _msgSender(), tokenId, "");
        delete animals[tokenId];
        totalAnimalsStaked -= 1;
        emit AnimalClaimed(tokenId, 0, true);
      } else if (isPoacher(tokenId)) {
        alpha = _alphaForPoacher(tokenId);
        stake = poachers[alpha][poacherIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalPoacherAlphaStaked -= alpha; // Remove Alpha from total staked
        _poacherDeposits[msg.sender].remove(tokenId);
        safari.safeTransferFrom(address(this), _msgSender(), tokenId, "");
	// Shuffle last Poacher to current position
        lastStake = poachers[alpha][poachers[alpha].length - 1];
        poachers[alpha][poacherIndices[tokenId]] = lastStake;
        poacherIndices[lastStake.tokenId] = poacherIndices[tokenId];
        poachers[alpha].pop(); // Remove duplicate
        delete poacherIndices[tokenId]; // Delete old mapping
        emit PoacherClaimed(tokenId, 0, true);
      }
    }
  }

    /** READ */

    function getUnclaimedRuby(uint256 tokenId) external view returns(uint256) {
    	uint256 owed;
        Stake memory stake;
        uint8 alpha;

        if (isAnimal(tokenId)) {
            stake = animals[tokenId];
            if ((uint256(totalRubyEarned) * 1 ether) < MAXIMUM_GLOBAL_RUBY) {
                owed = (block.timestamp - stake.value) * DAILY_RUBY_RATE / 1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $RUBY production stopped already
            } else {
                owed = (lastClaimTimestamp - stake.value) * DAILY_RUBY_RATE / 1 days;
            }
        } else if (isPoacher(tokenId)) {
            alpha = _alphaForPoacher(tokenId);
            stake = poachers[alpha][poacherIndices[tokenId]];
            owed = alpha * (rubyPerPoacherAlpha - stake.value) * 1 ether / 100;
        }
	return owed;
    }

    function depositsOf(address account) external view returns (uint256[] memory) {
        uint256[] memory _animals = _depositedAnimalsOf(account);
        uint256[] memory _poachers = _depositedPoachersOf(account);
        uint256[] memory _aprs = _depositedAPRsOf(account);
        uint256[] memory tokenIds = new uint256[](_animals.length + _poachers.length + _aprs.length);
        uint256 i;
        uint256 j = 0;
        for (i=0; i<_animals.length; i++) {
            tokenIds[j] = _animals[i];
	    j++;
        }
        for (i=0; i<_poachers.length; i++) {
            tokenIds[j] = _poachers[i];
	    j++;
        }
        for (i=0; i<_aprs.length; i++) {
            tokenIds[j] = _aprs[i];
	    j++;
        }
        return tokenIds;
    }

    function depositedAnimalsOf(address account) external view returns (uint256[] memory) {
        return _depositedAnimalsOf(account);
    }

    function _depositedAnimalsOf(address account) private view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _animalDeposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function depositedPoachersOf(address account) external view returns (uint256[] memory) {
        return _depositedPoachersOf(account);
    }

    function _depositedPoachersOf(address account) private view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _poacherDeposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function depositedAPRsOf(address account) external view returns (uint256[] memory) {
        return _depositedAPRsOf(account);
    }

    function _depositedAPRsOf(address account) private view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _aprDeposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function numDepositedPoachersOf(address account) external view returns (uint256) {
        return _poacherDeposits[account].length();
    }

    function numDepositedAPRsOf(address account) external view returns (uint256) {
        return _aprDeposits[account].length();
    }

    function getStakedCount() external view returns (uint256, uint256)
    {
        uint256 totalStakedCount = safari.balanceOf(address(this));

        return(totalAnimalsStaked, totalStakedCount - totalAnimalsStaked);
    }

    function getStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
        return(uint256(totalRubyEarned) * 1 ether, totalAnimalsStaked, totalPoacherAlphaStaked, uint256(rubyPerPoacherAlpha) * 1 ether / 100, lastClaimTimestamp, unaccountedRewards);
    }

  /** ACCOUNTING */

  /** 
   * add $RUBY to claimable pot for the Pack
   * @param amount $RUBY to add to the pot
   */
  function _payPoacherTax(uint40 amount) internal {
    // if there's no staked poachers
    if (totalPoacherAlphaStaked == 0) {
      unaccountedRewards += amount;
      return;
    }
    // makes sure to include any unaccounted $RUBY 
    rubyPerPoacherAlpha += uint40(100 * (amount + unaccountedRewards) / totalPoacherAlphaStaked);
    unaccountedRewards = 0;
  }

  modifier _updateEarnings() {
    if ((uint256(totalRubyEarned) * 1 ether) < MAXIMUM_GLOBAL_RUBY) {
      totalRubyEarned += uint40(
        (block.timestamp - lastClaimTimestamp)
        * totalAnimalsStaked
        * DAILY_RUBY_RATE / 1 days / 1 ether
      );
      lastClaimTimestamp = uint32(block.timestamp);
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
   * checks if a token is an Animal
   * @param tokenId the ID of the token to check
   * @return isAnimal - whether or not a token is an Animal
   */
  function isAnimal(uint256 tokenId) public view returns (bool) {
    return safari.isAnimal(tokenId);
  }

  function isPoacher(uint256 tokenId) public view returns (bool) {
    return safari.isPoacher(tokenId);
  }

  /**
   * gets the alpha score of a Poacher
   * @param tokenId the ID of the Poacher
   * @return the alpha score of the Poacher
   */
  function _alphaForPoacher(uint256 tokenId) internal view returns (uint8) {
    return safari.tokenAlpha(tokenId);
  }

  /**
   * gets the alpha score of a Poacher
   * @param tokenId the ID of the Poacher
   * @return the alpha score of the Poacher
   */
  function _alphaForAPR(uint256 tokenId) internal view returns (uint8) {
    return safari.tokenAlpha(tokenId);
  }

  /**
   * chooses a random Poacher owner when a newly minted token is stolen
   * @param seed a random value used to choose a Poacher
   * @return the owner of the randomly selected Poacher
   */
  function randomPoacherOwner(uint256 seed) external view returns (address) {
    if (totalPoacherAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalPoacherAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each set of Poachers with the same alpha score
    for (uint i = MIN_ALPHA; i <= MAX_ALPHA; i++) {
      cumulative += poachers[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Poacher with that alpha score
      return poachers[i][seed % poachers[i].length].owner;
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
      require(from == address(0x0), "Cannot send tokens to Reserve directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}
