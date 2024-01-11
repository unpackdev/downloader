// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

import "./ISablier.sol";
import "./ITimeLockPool.sol";

contract DiamondRewardPool is Initializable, ITimeLockPool, ContextUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event DepositEscrowReward(address indexed _receiver, uint256 _duration, uint256 _amount, uint256 _streamId);

  IERC721Upgradeable public rewardToken;
  ISablier public sablier;
  
  uint256[] public deposits;
  mapping(address => uint256[]) public ownerStreams;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() initializer public {
      __Pausable_init();
      __AccessControl_init();
      __ReentrancyGuard_init();
      __Context_init();

      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(PAUSER_ROLE, msg.sender);

      _pause();
  }

  function setContracts(
    IERC721Upgradeable _rewardToken,
    ISablier _sablier
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rewardToken = _rewardToken;
    sablier = _sablier;
  }

  function deposit(uint256 _amount, uint256 _duration, address _receiver) external override whenNotPaused nonReentrant onlyRole(OPERATOR_ROLE) {
    uint256 depositAmount = _amount - (_amount % _duration); // not quite the full amount so it's divisible
    uint256 startTime = block.timestamp;
    uint256 stopTime = block.timestamp + _duration;

    // send from staking pool to this pool so we can send to Sablier
    rewardToken.transferFrom(_msgSender(), address(this), depositAmount);
    rewardToken.approve(address(sablier), depositAmount); // approve the transfer

    // the stream id is needed later to withdraw from or cancel the stream
    uint256 streamId = sablier.createStream(_receiver, depositAmount, address(rewardToken), startTime, stopTime);

    ownerStreams[_receiver].push(streamId);

    emit DepositEscrowReward(_receiver, _duration, depositAmount, streamId);
  }

  function pause() external onlyRole(PAUSER_ROLE) {
      _pause();
  }

  function unpause() external onlyRole(PAUSER_ROLE) {
      _unpause();
  }

  function getStreams(address owner) external view returns (uint256[] memory) {
    return ownerStreams[owner];
  }

  function withdrawStreams(uint256[] memory streamIds, uint256[] memory funds) public nonReentrant {
    for (uint i = 0; i < streamIds.length; i++) {
      sablier.withdrawFromStream(streamIds[i], funds[i]);
    }
  }

  /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
  uint256[42] private __gap;
}