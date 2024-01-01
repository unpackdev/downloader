// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FullMath.sol";
import "./TransferHelper.sol";
import "./Signature.sol";

import "./ECDSA.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";

struct UserHarvest {
  uint256 amount;
  uint256 claimedAmount;
  uint256 latestVesting;
}

struct Winner {
  address wallet;
  uint256 amount;
}

struct Mission {
  uint256 startTime;
  uint256 endTime;
  address token;
  uint256 totalAmount;
  uint256 distributedAmount;
  uint256[] schedules;
  uint256 windowPeriod;
}

contract MissionMint is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  using ECDSA for bytes32;

  /// @dev save list process user harvest
  mapping(string => mapping(address => UserHarvest)) public userHarvests;

  /// @dev list missions (missionId => Mission)
  mapping(string => Mission) internal missions;

  address public signer;
  address public treasury;
  uint128 public fee; // 100% = 100000

  event RegisterMission(address sender, string missionId, address tokenAddress);
  event Vesting(
    address sender,
    string mission,
    address receiver,
    uint256 amount,
    uint256 time
  );
  event SetSigner(address sender, address signer);
  event SetTreasury(address sender, address treasury);
  event SetFee(address sender, uint newFee);

  /// @notice constructor
  /// @dev Initial function
  /// @param _fee Fee when user claim token
  /// @param _signer Signer who will sign transaction
  /// @param _treasury Wallet will receive fee
  function initialize(
    uint128 _fee,
    address _signer,
    address _treasury
  ) public initializer {
    require(_signer != address(0), "signer address is invalid");
    require(_treasury != address(0), "treasury address is invalid");

    __Ownable_init();
    __UUPSUpgradeable_init();

    signer = _signer;
    fee = _fee;
    treasury = _treasury;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  /// @dev Check signature of transaction
  /// @param _messageHash Message hash
  /// @param _signature Signature string
  function validateSignature(
    bytes32 _messageHash,
    bytes memory _signature
  ) internal view {
    require(
      Signature.getSigner(_messageHash, _signature) == signer,
      "Signature validation failed"
    );
  }

  function getMissionTokenAmount(
    string memory id
  ) external view returns (uint256) {
    return missions[id].totalAmount;
  }

  /// @dev Setting fee
  /// @param _fee New fee
  function setFee(uint128 _fee) public onlyOwner {
    fee = _fee;

    emit SetFee(msg.sender, fee);
  }

  /// @dev Setting signer
  /// @param _signer New signer
  function setSigner(address _signer) public onlyOwner {
    require(_signer != address(0), "signer address is invalid");
    signer = _signer;

    emit SetSigner(msg.sender, signer);
  }

  /// @dev Setting treasury
  /// @param _treasury New treasury
  function setTreasury(address _treasury) public onlyOwner {
    require(_treasury != address(0), "treasury address is invalid");
    treasury = _treasury;

    emit SetTreasury(msg.sender, treasury);
  }

  /// @notice Register new mission to distribute token
  /// @dev Register new mission
  /// @param id id of new mission
  /// @param _startTime Start time of mission
  /// @param _endTime End time of mission
  /// @param _vestingSchedule Vesting schedule times. [1694416123, 1694417773, 1694418883, ...]
  /// @param _windowPeriod Claimable time.
  /// @param token token address which is distributed
  /// @param _totalAmount Total token amount will be sent to this contract for distribute action
  function registerMission(
    string memory id,
    uint256 _startTime,
    uint256 _endTime,
    uint256[] memory _vestingSchedule,
    uint256 _windowPeriod,
    address token,
    uint256 _totalAmount,
    bytes memory _signature
  ) public payable virtual {
    bytes32 messageHash = keccak256(
      abi.encodePacked(address(this), msg.sender, id, token, _totalAmount)
    );
    validateSignature(messageHash, _signature);

    validateRegister(
      id,
      _startTime,
      _endTime,
      _vestingSchedule,
      _windowPeriod,
      token,
      _totalAmount
    );

    uint256[] memory schedules;
    if (_vestingSchedule.length == 0) {
      schedules = new uint256[](1);
      schedules[0] = _endTime;
    } else {
      schedules = _vestingSchedule;
    }

    TransferHelper.safeTransferFrom(
      token,
      msg.sender,
      address(this),
      _totalAmount
    );

    Mission memory mission = Mission({
      startTime: _startTime,
      endTime: _endTime,
      token: token,
      totalAmount: _totalAmount,
      distributedAmount: 0,
      schedules: schedules,
      windowPeriod: _windowPeriod
    });

    missions[id] = mission;

    emit RegisterMission(msg.sender, id, token);
  }

  /// @notice wallet claim token after mission finished
  /// @dev Winnet claim token
  /// @param receiver id of new mission
  /// @param missionId Start time of mission
  /// @param totalReward Total reward amount of sender
  /// @param signature End time of mission
  function vesting(
    address receiver,
    string memory missionId,
    uint256 totalReward,
    bytes memory signature
  ) public nonReentrant {
    bytes32 messageHash = keccak256(
      abi.encodePacked(address(this), receiver, missionId)
    );
    validateSignature(messageHash, signature);

    validateVesting(receiver, missionId, block.timestamp);

    (uint256 amountClaimable, uint256 vestingTime) = caculateTokenClaimable(
      missionId,
      receiver,
      totalReward
    );

    // check total distributed amount of this mission
    validateDistributedAmount(missionId, receiver, amountClaimable);

    require(amountClaimable > 0, "Nothing to claim");

    uint feeAmount = (amountClaimable * fee) / 100000;

    TransferHelper.safeTransfer(
      missions[missionId].token,
      receiver,
      amountClaimable - feeAmount
    );

    TransferHelper.safeTransfer(missions[missionId].token, treasury, feeAmount);

    UserHarvest storage userHarvest = userHarvests[missionId][receiver];
    userHarvest.latestVesting = vestingTime;
    userHarvest.claimedAmount += amountClaimable;

    emit Vesting(msg.sender, missionId, receiver, amountClaimable, vestingTime);
  }

  /// @dev caculate amount claimable token now
  /// @param missionId mission id
  /// @param receiver address of wallet which claim token
  /// @param totalReward total reward amount of sender
  /// @return amountClaimable amount token this wallet can claim now
  /// @return vestingTime vesting time is a period which this wallet claimed token of it. Eg: VestingSchedule: [1694411111, 1694422222, 1694433333] and vestingTime = 1694422222 mean this wallet claimed token of 1694411111 and 1694422222
  function caculateTokenClaimable(
    string memory missionId,
    address receiver,
    uint256 totalReward
  ) public view returns (uint256 amountClaimable, uint256 vestingTime) {
    require(bytes(missionId).length != 0, "Mission id is empty");

    UserHarvest memory user = userHarvests[missionId][receiver];
    Mission memory currentMission = missions[missionId];
    uint[] memory vestingSchedules = currentMission.schedules;
    uint countClaimedTime = 0;

    for (uint i = 0; i < vestingSchedules.length; ++i) {
      if (vestingSchedules[i] <= block.timestamp) {
        countClaimedTime++;
        vestingTime = vestingSchedules[i];
      }
    }

    if (countClaimedTime == vestingSchedules.length) {
      amountClaimable = totalReward - user.claimedAmount;
    } else {
      // (a*b)/c
      amountClaimable =
        FullMath.mulDiv(
          totalReward,
          countClaimedTime,
          vestingSchedules.length
        ) -
        user.claimedAmount;
    }

    return (amountClaimable, vestingTime);
  }

  /// @dev Check total token distributed of this mission
  /// @param missionId id of mission
  /// @param receiver address of wallet which will claim
  /// @param amount amount token which will be claimed
  function validateDistributedAmount(
    string memory missionId,
    address receiver,
    uint amount
  ) private view {
    Mission memory currentMission = missions[missionId];

    UserHarvest memory user = userHarvests[missionId][receiver];

    // user.amount = 0 ==> first time user claim token in this missionId
    if (user.amount == 0) {
      require(
        amount < currentMission.totalAmount - currentMission.distributedAmount,
        "Amount claim is invalid"
      );
    }
  }

  /// @dev Validate before vesting
  /// @param receiver address of wallet which will claim
  /// @param missionId mission of id
  /// @param currentTime Time of block currently
  function validateVesting(
    address receiver,
    string memory missionId,
    uint currentTime
  ) private view {
    Mission memory mission = missions[missionId];

    require(receiver != address(0), "receiver address is invalid");
    require(mission.schedules[0] <= currentTime, "Vesting time is not started");
    require(
      currentTime <= mission.endTime + mission.windowPeriod,
      "Vesting time is end"
    );
  }

  /// @dev validate before register
  function validateRegister(
    string memory id,
    uint256 _startTime,
    uint256 _endTime,
    uint256[] memory _vestingSchedule,
    uint256 _windowPeriod,
    address token,
    uint256 _totalAmount
  ) internal view virtual {
    require(_endTime > _startTime, "endTime must greater than startTime");
    require(_startTime > block.timestamp, "startTime must is a future time");
    require(token != address(0), "Token address is invalid");
    require(_totalAmount > 0, "Total amount token is invalid");
    require(bytes(id).length != 0, "Mission id is empty");
    require(missions[id].token == address(0), "This mission is existed");

    validateVestingSchedule(_vestingSchedule, _endTime, _windowPeriod);
  }

  /// @dev validate vesting schedule
  function validateVestingSchedule(
    uint256[] memory _vestingSchedule,
    uint256 _endTime,
    uint256 _windowPeriod
  ) private pure {
    uint length = _vestingSchedule.length;
    if (length > 0) {
      require(_vestingSchedule[0] >= _endTime, "Vesting schedule is invalid");
      require(
        _vestingSchedule[length - 1] < _endTime + _windowPeriod,
        "vestingSchedule or windowPeriod is invalid"
      );
    }
  }
}
