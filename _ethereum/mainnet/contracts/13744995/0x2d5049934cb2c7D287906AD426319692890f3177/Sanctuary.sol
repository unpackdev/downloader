// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.10;

import "IERC721Receiver.sol";
import "Context.sol";
import "Angelz.sol";
import "Grace.sol";

contract Sanctuary is IERC721Receiver, Context {
  // maximum angelic score for a Angel
  uint8 public constant MAX_ANGELIC = 8;
  bool public pauseSanctuary = false;
  address public immutable ownerContract;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event HumanClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event AngelClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Angelz NFT contract
  Angelz angelz;
  // reference to the $GRACE contract for minting $GRACE earnings
  GRACE grace;

  // maps tokenId to stake
  mapping(uint256 => Stake) public sanctuary;
  // maps angelic to all Angel stakes with that angelic
  mapping(uint256 => Stake[]) public heaven;
  // tracks location of each Angel in Heaven
  mapping(uint256 => uint256) public heavenIndices;
  // total angelic scores staked
  uint256 public totalAngelicStaked = 0;
  // any rewards distributed when no angels are staked
  uint256 public unaccountedRewards = 0;
  // amount of $GRACE due for each angelic point staked
  uint256 public gracePerAngelic = 0;

  // human earn 5000 $GRACE per day
  uint256 public constant DAILY_GRACE_RATE = 5000 ether;
  // human must have 2 days worth of $GRACE to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 3 days;
  // angels take a 20% tax on all $GRACE claimed
  uint256 public constant GRACE_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 1.2 billion $GRACE earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GRACE = 1200000000 ether;

  // amount of $GRACE earned so far
  uint256 public totalGraceEarned;
  // number of Human staked in the Sanctuary
  uint256 public totalHumanStaked;
  // the last time $GRACE was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GRACE
  bool public rescueEnabled = false;

  /**
   * @param _angelz reference to the Angelz NFT contract
   * @param _grace reference to the $GRACE token
   */
  constructor(address _angelz, address _grace) {
    angelz = Angelz(_angelz);
    grace = GRACE(_grace);
    ownerContract = msg.sender;
  }

  modifier sanctuaryOpen() {
    require(!pauseSanctuary, "PauseSanctuary");
    _;
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    require(msg.sender == ownerContract, "onlyOwner");
  }

  /** STAKING */

  /**
   * adds Human and angels to the Sanctuary and Heaven
   * @param account the address of the staker
   * @param tokenIds the IDs of the Human and angels to stake
   */
  function addManyToSanctuaryAndHeaven(
    address account,
    uint16[] calldata tokenIds
  ) external {
    require(
      account == _msgSender() || _msgSender() == address(angelz),
      "DONT GIVE YOUR TOKENS AWAY"
    );
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(angelz)) {
        // dont do this step if its a mint + stake
        require(angelz.ownerOf(tokenIds[i]) == _msgSender(), "NOT YOUR TOKEN");
        angelz.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isHuman(tokenIds[i])) _addHumanToSanctuary(account, tokenIds[i]);
      else _addAngelToHeaven(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Human to the Sanctuary
   * @param account the address of the staker
   * @param tokenId the ID of the Human to add to the Sanctuary
   */
  function _addHumanToSanctuary(address account, uint256 tokenId)
    internal
    sanctuaryOpen
    _updateEarnings
  {
    sanctuary[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalHumanStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Angel to the Heaven
   * @param account the address of the staker
   * @param tokenId the ID of the Angel to add to the Heaven
   */
  function _addAngelToHeaven(address account, uint256 tokenId) internal {
    uint256 angelic = _angelicForAngel(tokenId);
    totalAngelicStaked += angelic; // Portion of earnings ranges from 8 to 5
    heavenIndices[tokenId] = heaven[angelic].length; // Store the location of the Angel in the Heaven
    heaven[angelic].push(
      Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(gracePerAngelic)
      })
    ); // Add the Angel to the Heaven
    emit TokenStaked(account, tokenId, gracePerAngelic);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GRACE earnings and optionally unstake tokens from the Sanctuary / Heaven
   * to unstake a Human it will require it has 2 days worth of $GRACE unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromSanctuaryAndHeaven(
    uint16[] calldata tokenIds,
    bool unstake
  ) external sanctuaryOpen _updateEarnings {
    uint256 owed = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (isHuman(tokenIds[i]))
        owed += _claimHumanFromSanctuary(tokenIds[i], unstake);
      else owed += _claimAngelFromHeaven(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    grace.mint(_msgSender(), owed);
  }

  /**
   * realize $GRACE earnings for a single Human and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked angels
   * if unstaking, there is a 50% chance all $GRACE is stolen
   * @param tokenId the ID of the Human to claim earnings from
   * @param unstake whether or not to unstake the Human
   * @return owed - the amount of $GRACE earned
   */
  function _claimHumanFromSanctuary(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    Stake memory stake = sanctuary[tokenId];
    require(stake.owner == _msgSender(), "stealingBAD");
    require(
      !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
      "NEED THREE DAY'S GRACE"
    );
    if (totalGraceEarned < MAXIMUM_GLOBAL_GRACE) {
      owed = ((block.timestamp - stake.value) * DAILY_GRACE_RATE) / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GRACE production stopped already
    } else {
      owed = ((lastClaimTimestamp - stake.value) * DAILY_GRACE_RATE) / 1 days; // stop earning additional $GRACE if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) {
        // 50% chance of all $GRACE stolen
        _payAngelTax(owed);
        owed = 0;
      }
      delete sanctuary[tokenId];
      totalHumanStaked -= 1;
      angelz.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Human
    } else {
      _payAngelTax((owed * GRACE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked angels
      owed = (owed * (100 - GRACE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Human owner
      sanctuary[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit HumanClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $GRACE earnings for a single Angel and optionally unstake it
   * angels earn $GRACE proportional to their Angelic rank
   * @param tokenId the ID of the Angel to claim earnings from
   * @param unstake whether or not to unstake the Angel
   * @return owed - the amount of $GRACE earned
   */
  function _claimAngelFromHeaven(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    require(
      angelz.ownerOf(tokenId) == address(this),
      "NOT A PART OF THE HEAVEN"
    );
    uint256 angelic = _angelicForAngel(tokenId);
    Stake memory stake = heaven[angelic][heavenIndices[tokenId]];
    require(stake.owner == _msgSender(), "stealingBAD");
    owed = (angelic) * (gracePerAngelic - stake.value); // Calculate portion of tokens based on Angelic
    if (unstake) {
      totalAngelicStaked -= angelic; // Remove Angelic from total staked
      Stake memory lastStake = heaven[angelic][heaven[angelic].length - 1];
      heaven[angelic][heavenIndices[tokenId]] = lastStake; // Shuffle last Angel to current position
      heavenIndices[lastStake.tokenId] = heavenIndices[tokenId];
      heaven[angelic].pop(); // Remove duplicate
      delete heavenIndices[tokenId]; // Delete old mapping
      angelz.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Angel
    } else {
      heaven[angelic][heavenIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(gracePerAngelic)
      }); // reset stake
    }
    emit AngelClaimed(tokenId, owed, unstake);
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
    uint256 angelic;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isHuman(tokenId)) {
        stake = sanctuary[tokenId];
        require(stake.owner == _msgSender(), "stealingBAD");
        delete sanctuary[tokenId];
        totalHumanStaked -= 1;
        angelz.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Human
        emit HumanClaimed(tokenId, 0, true);
      } else {
        angelic = _angelicForAngel(tokenId);
        stake = heaven[angelic][heavenIndices[tokenId]];
        require(stake.owner == _msgSender(), "stealingBAD");
        totalAngelicStaked -= angelic; // Remove Angelic from total staked
        lastStake = heaven[angelic][heaven[angelic].length - 1];
        heaven[angelic][heavenIndices[tokenId]] = lastStake; // Shuffle last Angel to current position
        heavenIndices[lastStake.tokenId] = heavenIndices[tokenId];
        heaven[angelic].pop(); // Remove duplicate
        delete heavenIndices[tokenId]; // Delete old mapping
        angelz.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Angel
        emit AngelClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /**
   * add $GRACE to claimable pot for the Heaven
   * @param amount $GRACE to add to the pot
   */
  function _payAngelTax(uint256 amount) internal {
    if (totalAngelicStaked == 0) {
      // if there's no staked angels
      unaccountedRewards += amount; // keep track of $GRACE due to angels
      return;
    }
    // makes sure to include any unaccounted $GRACE
    gracePerAngelic += (amount + unaccountedRewards) / totalAngelicStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GRACE earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGraceEarned < MAXIMUM_GLOBAL_GRACE) {
      totalGraceEarned +=
        ((block.timestamp - lastClaimTimestamp) *
          totalHumanStaked *
          DAILY_GRACE_RATE) /
        1 days;
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
   * enables owner to pause / unpause sanctuary
   */
  function setPauseSanctuary(bool _setPauseSanctuary) external onlyOwner {
    if (_setPauseSanctuary) {
      pauseSanctuary = true;
    } else {
      pauseSanctuary = false;
    }
  }

  /** READ ONLY */

  /**
   * checks if a token is a Human
   * @param tokenId the ID of the token to check
   * @return human - whether or not a token is a Human
   */
  function isHuman(uint256 tokenId) public view returns (bool human) {
    (human, ) = angelz.tokenTraits(tokenId);
  }

  /**
   * gets the angelic score for a Angel
   * @param tokenId the ID of the Angel to get the angelic score for
   * @return the angelic score of the Angel (5-8)
   */
  function _angelicForAngel(uint256 tokenId) internal view returns (uint8) {
    (, uint8 angelicIndex) = angelz.tokenTraits(tokenId);
    // #######################
    return MAX_ANGELIC - angelicIndex; // angelic index is 0-3
  }

  /**
   * chooses a random Angel thief when a newly minted token is stolen
   * @param seed a random value to choose a Angel from
   * @return the owner of the randomly selected Angel thief
   */
  function randomAngelOwner(uint256 seed) external view returns (address) {
    if (totalAngelicStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAngelicStaked; // choose a value from 0 to total angelic staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of angels with the same angelic score
    for (uint256 i = MAX_ANGELIC - 3; i <= MAX_ANGELIC; i++) {
      cumulative += heaven[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Angel with that angelic score
      return heaven[i][seed % heaven[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      );
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send tokens to Sanctuary directly");
    return IERC721Receiver.onERC721Received.selector;
  }
}
