// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

import "./IDIAMOND.sol";
import "./ISablier.sol";

interface IDiamondHeist is IERC721Upgradeable, IERC721MetadataUpgradeable {
  struct LlamaDog {
    bool isLlama;
    uint8 body;
    uint8 hat;
    uint8 eye;
    uint8 mouth;
    uint8 clothes;
    uint8 tail;
    uint8 alphaIndex;
  }
  function minted() external view returns (uint256);
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (LlamaDog memory);
  function isLlama(uint256 tokenId) external view returns(bool);
  function addManyToStaking(address account, uint16[] calldata tokenIds) external;
}

interface ITimeLockPool {
    function deposit(uint256 _amount, uint256 _duration, address _receiver) external;
}

contract LlamaPoolV3 is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  event DepositLlama(address indexed owner, uint16[] indexed tokenIds, uint256 diamonds, uint256 streamId);
  event WithdrawLlama(address indexed owner, uint16[] indexed tokenIds, uint256 diamonds);
  event EmergencyWithdraw(address indexed owner, uint16[] indexed tokenIds);
  event EmergencyCancel(uint256[] indexed streams);

  IDiamondHeist public game;
  IDIAMOND public diamond;
  ISablier public sablier;

  uint256 public depositPct;
  uint256 public withdrawPct;

  // So first in, first out, so if you want to sweep the most recently added llama you'll have to
  // sweep them all in the pool.
  uint256 public depositCounter;
  uint256 public withdrawCounter;
  uint256[] public deposits;
  mapping(address => uint256[]) public ownerStreams;

  address public royaltyAddress;
  ITimeLockPool public rewardPool;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
      __Pausable_init();
      __Ownable_init();
      __ReentrancyGuard_init();
      __Context_init();

      depositPct = 150;
      withdrawPct = 175;

      _pause();
  }

  function setContracts(
    IDiamondHeist _diamondheist,
    IDIAMOND _diamond,
    ISablier _sablier
  ) external onlyOwner {
    game = _diamondheist;
    diamond = _diamond;
    sablier = _sablier;
  }

  function getBasePrice() public view returns (uint256) {
    uint256 tokenId = game.minted();
    if (tokenId <= 15000) return 2000 ether;
    if (tokenId <= 22500) return 5000 ether;
    if (tokenId <= 30000) return 10000 ether;
    return 20000 ether;
  }

  function getDepositPrice() public view returns (uint256) {
    return getBasePrice() * depositPct / 100;
  }

  function getWithdrawPrice() public view returns (uint256) {
    return getBasePrice() * withdrawPct / 100;
  }

  function count() public view returns (uint256) {
    return depositCounter - withdrawCounter;
  }

  function streamDiamond(address recipient, uint256 amount) internal returns (uint256, uint256) {
    diamond.mint(address(this), amount);
    rewardPool.deposit(amount, 864000, recipient);
    return (0, amount);
  }

  /**
   * @dev Deposits the given number of NFTs from the pool and receives a DIAMOND price
   */
  function deposit(uint16[] calldata tokenIds) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    require(tokenIds.length > 0, "No tokenIds");

    for (uint i = 0; i < tokenIds.length; i++) {
      require(game.isLlama(tokenIds[i]), "You can only deposit llamas");
      deposits.push(tokenIds[i]);
      depositCounter++;
      game.transferFrom(_msgSender(), address(this), tokenIds[i]);
    }
    
    // Depositors get paid 50% of mint cost
    uint256 reward = tokenIds.length * getDepositPrice();
    (uint256 streamId, uint256 depositAmount) = streamDiamond(_msgSender(), reward);

    emit DepositLlama(_msgSender(), tokenIds, depositAmount, streamId);
  }

  /**
   * @dev Withdraws the given number of NFTs from the pool and pays a DIAMOND price
   */
  function withdraw(uint256 amount) external whenNotPaused nonReentrant returns (uint16[] memory tokenIds) {
    require(tx.origin == _msgSender(), "Only EOA");
    require(amount <= count(), "Not enough llamas");
    // Withdrawers pay 80% (20% discount) of mint cost
    uint256 payment = amount * getWithdrawPrice();
    diamond.transferFrom(_msgSender(), royaltyAddress, payment);

    tokenIds = new uint16[](amount);
    for (uint i = 0; i < amount; i++) {
      tokenIds[i] = uint16(deposits[withdrawCounter]);
      withdrawCounter++;
    }
    game.addManyToStaking(address(_msgSender()), tokenIds);

    emit WithdrawLlama(_msgSender(), tokenIds, payment);
    return tokenIds;
  }

  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  function emergencyWithdraw(uint16[] memory tokenIds) external whenPaused onlyOwner {
    for (uint i = 0; i < tokenIds.length; i++) {
      game.transferFrom(address(this), address(_msgSender()), tokenIds[i]);
    }
    emit WithdrawLlama(_msgSender(), tokenIds, 0);
    emit EmergencyWithdraw(_msgSender(), tokenIds);
  }

  function emergencyCancel(uint256[] memory streamIds) external whenPaused onlyOwner {
    for (uint256 index = 0; index < streamIds.length; index++) {
      sablier.cancelStream(streamIds[index]);
    }
    emit EmergencyCancel(streamIds);
  }

  function getStreams(address owner) external view returns (uint256[] memory) {
    return ownerStreams[owner];
  }

  function withdrawStreams(uint256[] memory streamIds, uint256[] memory funds) external nonReentrant {
    for (uint i = 0; i < streamIds.length; i++) {
      sablier.withdrawFromStream(streamIds[i], funds[i]);
    }
  }

  function setPercentages(uint256 _newDeposit, uint256 _newWithdraw) external onlyOwner {
    depositPct = _newDeposit;
    withdrawPct = _newWithdraw;
  }

  function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
    royaltyAddress = _royaltyAddress;
  }
  function setRewardPool(ITimeLockPool _rewardPool) external onlyOwner {
    if (address(rewardPool) != address(0)) {
        diamond.approve(address(rewardPool), 0);
    }
    rewardPool = _rewardPool;
    diamond.approve(address(rewardPool), 2**256 - 1);
  }

  /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
  uint256[40] private __gap;
}