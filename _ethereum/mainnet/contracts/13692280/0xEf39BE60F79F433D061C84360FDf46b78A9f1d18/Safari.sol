// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Lioon.sol";
import "./STRIPES.sol";

import "./EnumerableSet.sol";

contract Safari is Ownable, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

  // maximum alpha score for a Lion
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event ZebraClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event LionClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Lionzebra NFT contract
  Lioon lioon;
  // reference to the $STRIPES contract for minting $STRIPES earnings
  STRIPES stripes;

  // maps tokenId to stake
  mapping(uint256 => Stake) public safari; 
  // maps alpha to all Lion stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Lion in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $STRIPES due for each alpha point staked
  uint256 public stripesPerAlpha = 0; 

  // zebra earn 10000 $STRIPES per day
  uint256 public constant DAILY_STRIPES_RATE = 10000 ether;
  // zebra must have 2 days worth of $STRIPES to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // wolves take a 20% tax on all $STRIPES claimed
  uint256 public constant STRIPES_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $STRIPES earned through staking
  uint256 public constant MAXIMUM_GLOBAL_STRIPES = 2400000000 ether;

  // amount of $STRIPES earned so far
  uint256 public totalStripesEarned;
  // number of Zebra staked in the Safari
  uint256 public totalZebraStaked;
  // the last time $STRIPES was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $STRIPES
  bool public rescueEnabled = false;

    mapping(address => EnumerableSet.UintSet) private _deposits;

  /**
   * @param _lioon reference to the Lionzebra NFT contract
   * @param _stripes reference to the $STRIPES token
   */
  constructor(address _lioon, address _stripes) { 
    lioon = Lioon(_lioon);
    stripes = STRIPES(_stripes);
  }

  /** STAKING */

  /**
   * adds Zebra and Lions to the Safari and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Zebra and Lions to stake
   */
  function addManyToSafariAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(lioon), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(lioon)) { // dont do this step if its a mint + stake
        require(lioon.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        lioon.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isZebra(tokenIds[i])) 
        _addZebraToSafari(account, tokenIds[i]);
      else 
        _addLionToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Zebra to the Safari
   * @param account the address of the staker
   * @param tokenId the ID of the Zebra to add to the Safari
   */
  function _addZebraToSafari(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    safari[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    _deposits[account].add(tokenId);
    totalZebraStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Lion to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Lion to add to the Pack
   */
  function _addLionToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForLion(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the lion in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(stripesPerAlpha)
    })); // Add the lion to the Pack
    _deposits[account].add(tokenId);
    emit TokenStaked(account, tokenId, stripesPerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $STRIPES earnings and optionally unstake tokens from the Safari / Pack
   * to unstake a Zebra it will require it has 2 days worth of $STRIPES unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromSafariAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isZebra(tokenIds[i]))
        owed += _claimZebraFromSafari(tokenIds[i], unstake);
      else
        owed += _claimLionFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    stripes.mint(_msgSender(), owed);
  }

  /**
   * realize $STRIPES earnings for a single Zebra and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Lions
   * if unstaking, there is a 50% chance all $STRIPES is stolen
   * @param tokenId the ID of the Zebra to claim earnings from
   * @param unstake whether or not to unstake the Zebra
   * @return owed - the amount of $STRIPES earned
   */
  function _claimZebraFromSafari(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = safari[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S STRIPES");
    if (totalStripesEarned < MAXIMUM_GLOBAL_STRIPES) {
      owed = (block.timestamp - stake.value) * DAILY_STRIPES_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $STRIPES production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_STRIPES_RATE / 1 days; // stop earning additional $STRIPES if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $STRIPES stolen
        _payLionTax(owed);
        owed = 0;
      }
      _deposits[msg.sender].remove(tokenId);
      delete safari[tokenId];
      lioon.transferFrom(address(this), _msgSender(), tokenId); // send back Zebra
      totalZebraStaked -= 1;
    } else {
      _payLionTax(owed * STRIPES_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked wolves
      owed = owed * (100 - STRIPES_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Zebra owner
      safari[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit ZebraClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $STRIPES earnings for a single Lion and optionally unstake it
   * Lions earn $STRIPES proportional to their Alpha rank
   * @param tokenId the ID of the Lion to claim earnings from
   * @param unstake whether or not to unstake the Lion
   * @return owed - the amount of $STRIPES earned
   */
  function _claimLionFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(lioon.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForLion(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (stripesPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      _deposits[msg.sender].remove(tokenId);
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Lion to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
      lioon.transferFrom(address(this), _msgSender(), tokenId); // Send back Lion
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(stripesPerAlpha)
      }); // reset stake
    }
    emit LionClaimed(tokenId, owed, unstake);
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
      if (isZebra(tokenId)) {
        stake = safari[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        _deposits[msg.sender].remove(tokenId);
        lioon.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Zebra
        delete safari[tokenId];
        totalZebraStaked -= 1;
        emit ZebraClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForLion(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        _deposits[msg.sender].remove(tokenId);
        lioon.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Lion
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Lion to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit LionClaimed(tokenId, 0, true);
      }
    }
  }

    /** READ */

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function getStakedCount() external view returns (uint256, uint256)
    {
        uint256 totalStakedCount = lioon.balanceOf(address(this));

        return(totalZebraStaked, totalStakedCount - totalZebraStaked);
    }

    function getStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
        return(totalStripesEarned, totalZebraStaked, totalAlphaStaked, stripesPerAlpha, lastClaimTimestamp, unaccountedRewards);
    }

  /** ACCOUNTING */

  /** 
   * add $STRIPES to claimable pot for the Pack
   * @param amount $STRIPES to add to the pot
   */
  function _payLionTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked wolves
      unaccountedRewards += amount; // keep track of $STRIPES due to wolves
      return;
    }
    // makes sure to include any unaccounted $STRIPES 
    stripesPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $STRIPES earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalStripesEarned < MAXIMUM_GLOBAL_STRIPES) {
      totalStripesEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalZebraStaked
        * DAILY_STRIPES_RATE / 1 days; 
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
   * checks if a token is a Zebra
   * @param tokenId the ID of the token to check
   * @return zebra - whether or not a token is a Zebra
   */
  function isZebra(uint256 tokenId) public view returns (bool) {
    //(sheep, , , , , , , , , ) = woolf.tokenTraits(tokenId);
    bool isLion;
    (isLion, ) = lioon._idData(tokenId);
    return !isLion;
  }

  /**
   * gets the alpha score for a Lion
   * @param tokenId the ID of the Lion to get the alpha score for
   * @return the alpha score of the Lion (5-8)
   */
  function _alphaForLion(uint256 tokenId) internal view returns (uint8) {
    uint8 alpha;
    (, alpha) = lioon._idData(tokenId);
    return alpha;
  }

  /**
   * chooses a random Lion thief when a newly minted token is stolen
   * @param seed a random value to choose a Lion from
   * @return the owner of the randomly selected Lion thief
   */
  function randomLionOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Lions with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Lion with that alpha score
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
      require(from == address(0x0), "Cannot send tokens to Safari directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}