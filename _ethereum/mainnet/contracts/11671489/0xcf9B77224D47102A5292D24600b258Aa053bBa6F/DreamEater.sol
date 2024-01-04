pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./SafeMath.sol";

// Interface for Aion
abstract contract Aion {
  uint256 public serviceFee;

  function ScheduleCall(
    uint256 blocknumber,
    address to,
    uint256 value,
    uint256 gaslimit,
    uint256 gasprice,
    bytes calldata,
    bool schedType
  ) public payable virtual returns (uint256, address);
}

interface DreamInterface {
  function approve(address spender, uint256 amount) external returns (bool);

  function _burn(address whom, uint256 amount) external;

  function balanceOf(address account) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DreamEater is AccessControlUpgradeSafe {
  using SafeMath for uint256;
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

  Aion aion;

  DreamInterface public DreamToken = DreamInterface(address(0xBbb8618aCA62671200EC702530c0514fB2C6871C));

  uint256 public DREAMboostLevelOneCost;
  uint256 public DREAMboostLevelTwoCost;
  uint256 public DREAMboostLevelThreeCost;
  uint256 public DREAMboostLevelFourCost;
  uint256 public DREAMboostLevelFiveCost;
  uint256 public DREAMboostLevelOneBonus;
  uint256 public DREAMboostLevelTwoBonus;
  uint256 public DREAMboostLevelThreeBonus;
  uint256 public DREAMboostLevelFourBonus;
  uint256 public DREAMboostLevelFiveBonus;
  uint256 public HourlyBurn;

  bool public dreamEaterLocked;

  mapping(address => uint256) public DREAMboostLevel;

  function init() external initializer {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    aion = Aion(0xCBe7AB529A147149b1CF982C3a169f728bC0C3CA);
    DREAMboostLevelOneCost = 10000e18; // 10,000 DREAM
    DREAMboostLevelTwoCost = 20000e18; // 20,000 DREAM
    DREAMboostLevelThreeCost = 30000e18; // 30,000 DREAM
    DREAMboostLevelFourCost = 40000e18; // 40,000 DREAM
    DREAMboostLevelFiveCost = 50000e18; // 50,000 DREAM
    DREAMboostLevelOneBonus = 1 * 10 * 17; // 10%
    DREAMboostLevelTwoBonus = 2 * 10 * 17; // 20%
    DREAMboostLevelThreeBonus = 3 * 10 * 17; // 30%
    DREAMboostLevelFourBonus = 4 * 10 * 17; // 40%
    DREAMboostLevelFiveBonus = 5 * 10 * 17; // 50%
  }

  function getDreamEaterMultiplier(address account) external view returns (uint256) {
    if (DREAMboostLevel[account] == 1) {
      return (DREAMboostLevelOneBonus);
    } else if (DREAMboostLevel[account] == 2) {
      return (DREAMboostLevelTwoCost);
    } else if (DREAMboostLevel[account] == 3) {
      return (DREAMboostLevelThreeBonus);
    } else if (DREAMboostLevel[account] == 4) {
      return (DREAMboostLevelFourBonus);
    } else if (DREAMboostLevel[account] == 5) {
      return (DREAMboostLevelFiveBonus);
    }
  }

  // Function to burn DREAM at input level, for input duration
  function lockinDREAMburn(
    uint256 burnlevel,
    uint256 durationHours,
    uint256 DREAMinput
  ) public {
    require(burnlevel > 0 && burnlevel < 6, "Input a valid DREAM burn level (1-5)");
    require(durationHours > 0, "DREAM burn duration must be greater than 0");
    require(dreamEaterLocked = false, "Dream Eater has been temporarily locked for use");

    if (burnlevel == 1) {
      HourlyBurn = DREAMboostLevelOneCost;
    } else if (burnlevel == 2) {
      HourlyBurn = DREAMboostLevelTwoCost;
    } else if (burnlevel == 3) {
      HourlyBurn = DREAMboostLevelThreeCost;
    } else if (burnlevel == 4) {
      HourlyBurn = DREAMboostLevelFourCost;
    } else if (burnlevel == 5) {
      HourlyBurn = DREAMboostLevelFiveCost;
    }

    require(DREAMinput >= HourlyBurn.mul(durationHours), "DREAM input is less than will be burned with parameters");

    DreamToken.approve(address(this), uint256(-1));

    uint256 DREAMburnAmount = HourlyBurn.mul(durationHours);
    DreamToken._burn(msg.sender, DREAMburnAmount);

    DREAMboostLevel[msg.sender] = burnlevel;

    bytes memory data = abi.encodeWithSelector(bytes4(keccak256("finishDREAMburnboost(address)")), msg.sender);
    uint256 callCost = 200000 * 1e9 + aion.serviceFee();
    aion.ScheduleCall{ value: callCost }(block.number + 15, address(this), 0, 200000, 1e9, data, false);
  }

  // Function to burn DREAM at input level, for as many hours as possible with current DREAM balance
  function maxDREAMburn(uint256 burnlevel, uint256 durationHours) public {
    require(burnlevel > 0 && burnlevel < 6, "Input a valid DREAM burn level (1-5)");
    require(durationHours > 0, "DREAM burn duration must be greater than 0");
    require(dreamEaterLocked = false, "Dream Eater has been temporarily locked for use");

    if (burnlevel == 1) {
      HourlyBurn = DREAMboostLevelOneCost;
    } else if (burnlevel == 2) {
      HourlyBurn = DREAMboostLevelTwoCost;
    } else if (burnlevel == 3) {
      HourlyBurn = DREAMboostLevelThreeCost;
    } else if (burnlevel == 4) {
      HourlyBurn = DREAMboostLevelFourCost;
    } else if (burnlevel == 5) {
      HourlyBurn = DREAMboostLevelFiveCost;
    }

    // Total DREAM of the function caller
    uint256 DreamBalance = DreamToken.balanceOf(msg.sender);

    // Determines any extra DREAM leftover after burning
    uint256 remainders = DreamBalance.mod(HourlyBurn);

    // Determines the total amount of DREAM to burn
    uint256 DREAMburnAmount = DreamBalance.div(HourlyBurn).sub(remainders);

    // Determines how many hours of boost the caller gains from DREAM burning
    uint256 HoursBurned = DREAMburnAmount.div(HourlyBurn);

    DreamToken.approve(address(this), uint256(-1));

    DreamToken._burn(msg.sender, DREAMburnAmount);
    DREAMboostLevel[msg.sender] = burnlevel;

    bytes memory data = abi.encodeWithSelector(bytes4(keccak256("finishDREAMburnboost(address)")), msg.sender);
    uint256 callCost = 200000 * 1e9 + aion.serviceFee();
    aion.ScheduleCall{ value: callCost }(block.number + 15, address(this), 0, 200000, 1e9, data, false);
  }

  function finishDREAMburnboost(address account) public {
    DREAMboostLevel[account] = 0;
  }

  function manualFinishDREAMburnboost(address account) public {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    DREAMboostLevel[account] = 0;
  }

  function lockDreamEaterPurchases() public {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    require(dreamEaterLocked = false, "Dream Eater is already locked");
    dreamEaterLocked = true;
  }

  function unlockDreamEaterPurchases() public {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    require(dreamEaterLocked = true, "Dream Eater is already unlocked");
    dreamEaterLocked = false;
  }

  // Changes the rates for how much each Dream Burn Boost Level costs, as well as what % boost it gives
  function changeDREAMPboostLevels(
    uint256 _DREAMboostLevelOneCost,
    uint256 _DREAMboostLevelTwoCost,
    uint256 _DREAMboostLevelThreeCost,
    uint256 _DREAMboostLevelFourCost,
    uint256 _DREAMboostLevelFiveCost,
    uint256 _DREAMboostLevelOneBonus,
    uint256 _DREAMboostLevelTwoBonus,
    uint256 _DREAMboostLevelThreeBonus,
    uint256 _DREAMboostLevelFourBonus,
    uint256 _DREAMboostLevelFiveBonus
  ) public {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    require(
      _DREAMboostLevelOneBonus < _DREAMboostLevelTwoBonus &&
        _DREAMboostLevelTwoBonus < _DREAMboostLevelThreeBonus &&
        _DREAMboostLevelThreeBonus < _DREAMboostLevelFourBonus &&
        _DREAMboostLevelThreeBonus < _DREAMboostLevelFiveBonus,
      "Boost Levels are not in ascending order"
    );
    DREAMboostLevelOneCost = _DREAMboostLevelOneCost;
    DREAMboostLevelTwoCost = _DREAMboostLevelTwoCost;
    DREAMboostLevelThreeCost = _DREAMboostLevelThreeCost;
    DREAMboostLevelFourCost = _DREAMboostLevelFourCost;
    DREAMboostLevelFiveCost = _DREAMboostLevelFiveCost;
    DREAMboostLevelOneBonus = _DREAMboostLevelOneBonus;
    DREAMboostLevelTwoBonus = _DREAMboostLevelTwoBonus;
    DREAMboostLevelThreeBonus = _DREAMboostLevelThreeBonus;
    DREAMboostLevelFourBonus = _DREAMboostLevelFourBonus;
    DREAMboostLevelFiveBonus = _DREAMboostLevelFiveBonus;
  }

  receive() external payable {}
}
