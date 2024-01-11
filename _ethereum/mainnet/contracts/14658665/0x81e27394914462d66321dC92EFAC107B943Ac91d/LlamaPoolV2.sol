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

contract LlamaPoolV2 is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
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

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
      __Pausable_init();
      __Ownable_init();
      __ReentrancyGuard_init();
      __Context_init();

      depositPct = 50;
      withdrawPct = 90;

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
    // Use sablier so we stream out for 10 days
    uint256 timeDelta = 864000; // 10 days
    uint256 depositAmount = amount - (amount % timeDelta); // not quite the full amount
    uint256 startTime = block.timestamp; // Now
    uint256 stopTime = block.timestamp + timeDelta; // 10 days from now

    diamond.mint(address(this), depositAmount);
    diamond.approve(address(sablier), depositAmount); // approve the transfer

    // the stream id is needed later to withdraw from or cancel the stream
    uint256 streamId = sablier.createStream(recipient, depositAmount, address(diamond), startTime, stopTime);
    ownerStreams[_msgSender()].push(streamId);
    return (streamId, depositAmount);
  }

  /**
   * @dev Deposits the given number of NFTs from the pool and receives a DIAMOND price
   */
  function deposit(uint16[] calldata tokenIds) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    require(tokenIds.length > 0, "No tokenIds");

    uint256 llamaBefore = game.balanceOf(address(this));
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
    require(game.balanceOf(address(this)) == llamaBefore + tokenIds.length, "Not received");
  }

  /**
   * @dev Withdraws the given number of NFTs from the pool and pays a DIAMOND price
   */
  function withdraw(uint256 amount) external whenNotPaused nonReentrant returns (uint16[] memory tokenIds) {
    require(tx.origin == _msgSender(), "Only EOA");
    require(amount <= count(), "Not enough llamas");

    uint256 llamaBefore = game.balanceOf(address(this));
    uint256 diamondBefore = diamond.balanceOf(address(_msgSender()));

    tokenIds = new uint16[](amount);
    for (uint i = 0; i < amount; i++) {
      tokenIds[i] = uint16(deposits[withdrawCounter]);
      withdrawCounter++;
    }
    game.addManyToStaking(address(_msgSender()), tokenIds);

    // Withdrawers pay 80% (20% discount) of mint cost
    uint256 payment = amount * getWithdrawPrice();
    diamond.burn(_msgSender(), payment);

    emit WithdrawLlama(_msgSender(), tokenIds, payment);

    require(game.balanceOf(address(this)) == llamaBefore - amount, "Not sent llama");
    require(diamond.balanceOf(_msgSender()) == diamondBefore - payment, "Not paid diamond");

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

  /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
  uint256[42] private __gap;
}