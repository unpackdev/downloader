// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

import "./IHouseGame.sol";
import "./ICash.sol";
import "./IRandomizer.sol";
import "./IRewardPool.sol";

contract Agent is Initializable, OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable {
  
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint8 tenantRating;
    uint16 tokenId;
    uint256 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, bool isHouse, uint256 value);
  event HouseClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event BuildingClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the HouseGame, $CASH and rewards contracts
  IHouseGame public house;
  ICASH public cash;
  IRewardPool public rewardPool;

  // maps tokenId to stake
  mapping(uint256 => Stake) public agent; 
  // maps tokenId to Building stakes
  mapping(uint256 => Stake) public pack; 
  // total building staked
  uint256 public totalBuildingStaked; 
  // any rewards distributed when no Building are staked
  uint256 public unaccountedRewards; 
  // amount of $CASH due for staked
  uint256 public totalReceivedBuidingTax; 

  // House must have 3 days worth of $CASH to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 3 days;
  // Building take a 25% tax on all $CASH claimed
  uint256 public constant BUILDING_CLAIM_TAX_PERCENTAGE = 25;

  // number of House staked in the Agent
  uint256 public totalHouseStaked;
  // the last time $CASH was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $CASH
  bool public rescueEnabled;

  IRandomizer public randomizer;

  /**
   * @param _house reference to the House NFT contract
   * @param _cash reference to the $CASH token
   */
  function initialize(address _house, address _cash, address _randomizer) external initializer { 
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();

    house = IHouseGame(_house);
    cash = ICASH(_cash);
    randomizer = IRandomizer(_randomizer);

    rescueEnabled = false;
  }

  /** STAKING */

  /**
   * adds House and Building to the Agent and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the House and Building to stake
   */
  function addManyToAgentAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(house), "DONT GIVE YOUR TOKENS AWAY");
    require(tokenIds.length > 0, "No token to stake");
    
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(house)) {
        require(house.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        house.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue;
      }

      if (isHouse(tokenIds[i])) 
        _addHouseToAgent(account, tokenIds[i]);
      else 
        _addBuildingToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single House to the Agent
   * @param account the address of the staker
   * @param tokenId the ID of the House to add to the Agent
   */
  function _addHouseToAgent(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    uint8 _random =  uint8(randomizer.random(tokenId) % 10 + 1);
    agent[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: block.timestamp, // solhint-disable-line not-rely-on-time
      tenantRating: _random
    });
    totalHouseStaked += 1;
    emit TokenStaked(account, tokenId, true, block.timestamp); // solhint-disable-line not-rely-on-time
  }

  /**
   * adds a single Building to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Building to add to the Pack
   */
  function _addBuildingToPack(address account, uint256 tokenId) internal {
    pack[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: totalReceivedBuidingTax,
      tenantRating : 0
    });
    totalBuildingStaked += 1;
    emit TokenStaked(account, tokenId, false, totalReceivedBuidingTax);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $CASH earnings and optionally unstake tokens from the Agent / Pack
   * to unstake a House it will require it has 3 days worth of $CASH unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   * @param burn unstake ALL of the tokens then burn all listed in tokenIds
   */
  function claimManyFromAgentAndPack(uint16[] calldata tokenIds, bool unstake, bool burn) external whenNotPaused _updateEarnings {
    require(tokenIds.length > 0, "No token to claim");
    if(burn) {
      require(unstake, "burn only when unstake");
    }
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isHouse(tokenIds[i]))
        owed += _claimHouseFromAgent(tokenIds[i], unstake);
      else
        owed += _claimBuildingFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    if (unstake && burn) {
      rewardPool.payTax(_msgSender(), owed);
      return;
    }
    cash.mint(_msgSender(), owed);
  }

  /**
   * realize $CASH earnings for a single House and optionally unstake it
   * if not unstaking, pay a 25% tax to the staked Building
   * @param tokenId the ID of the House to claim earnings from
   * @param unstake whether or not to unstake the House
   * @return owed - the amount of $CASH earned
   */
  function _claimHouseFromAgent(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake storage stake = agent[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT THREE DAY'S CASH"); // solhint-disable-line not-rely-on-time, reason-string
    if (stake.value > lastClaimTimestamp) {
      owed = 0; // $CASH production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * house.getIncomePerDay(tokenId) / 1 days;
    }
    uint256 _random = randomizer.random(tokenId) % 100 + 1;
    uint256 tax = owed * BUILDING_CLAIM_TAX_PERCENTAGE / 100;
    _payBuildingTax(tax); // percentage tax to staked building
    owed -= tax; // remainder goes to House owner
    if (_random > stake.tenantRating * 10) {
      owed = _propertyDamageTax(owed, house.getPropertyDamage(tokenId));
    }

    if (unstake) {
      _random = randomizer.random(tokenId) % 100 + 1;
      if (_random > stake.tenantRating * 10) {
        _payBuildingTax(owed);
        owed = 0;
      }
      house.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back House
      delete agent[tokenId];
      totalHouseStaked -= 1;
    } else {
      stake.value = block.timestamp; // solhint-disable-line not-rely-on-time
    }
    emit HouseClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $CASH earnings for a single Building and optionally unstake it
   * Building earn $CASH proportional to their Alpha rank
   * @param tokenId the ID of the Building to claim earnings from
   * @param unstake whether or not to unstake the Building
   * @return owed - the amount of $CASH earned
   */
  function _claimBuildingFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(house.ownerOf(tokenId) == address(this), "you're not part of this!");
    Stake memory stake = pack[tokenId];
    require(stake.owner == _msgSender(), "no stealing here");
    owed = totalReceivedBuidingTax - stake.value;
    if (unstake) {
      totalBuildingStaked--;
      house.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Building
      delete pack[tokenId];
    } else {
      pack[tokenId].value =  totalReceivedBuidingTax;
    }
    emit BuildingClaimed(tokenId, owed, unstake);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "RESCUE DISABLED");
    require(tokenIds.length > 0, "No token to rescue");
    uint256 tokenId;
    Stake memory stake;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isHouse(tokenId)) {
        stake = agent[tokenId];
        require(stake.owner == _msgSender(), "no stealing here");
        house.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back House
        delete agent[tokenId];
        totalHouseStaked -= 1;
        emit HouseClaimed(tokenId, 0, true);
      } else {
        stake = pack[tokenId];
        require(stake.owner == _msgSender(), "no stealing here");
        totalBuildingStaked -= 1;
        house.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Building
        delete pack[tokenId];
        emit BuildingClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $CASH to claimable pot for the Pack
   * @param amount $CASH to add to the pot
   */
  function _payBuildingTax(uint256 amount) internal {
    if (totalBuildingStaked == 0) { // if there's no staked building
      unaccountedRewards += amount; // keep track of $CASH due to building
      return;
    }
    // makes sure to include any unaccounted $CASH 
    totalReceivedBuidingTax += (amount + unaccountedRewards) / totalBuildingStaked;
    unaccountedRewards = 0;
  }

  function _propertyDamageTax(uint256 amount, uint256 _propertyDamage) internal pure returns(uint256) {
    return amount * (100 - _propertyDamage) / 100;
  }

  /**
   * tracks $CASH earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    lastClaimTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time
    _;
  }

  /** ADMIN */

  function setContracts(address _randomizer, address _rewardPool) external onlyOwner {
    require(_randomizer != address(0) && _rewardPool != address(0), "Invalid contract address");
    randomizer = IRandomizer(_randomizer);
    rewardPool = IRewardPool(_rewardPool);
  }

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
   * checks if a token is a House
   * @param tokenId the ID of the token to check
   * @return _house - whether or not a token is a House
   */
  function isHouse(uint256 tokenId) public view returns (bool _house) {
    _house = house.getTokenTraits(tokenId).isHouse;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Agent directly"); // solhint-disable-line reason-string
      return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}