// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IMintReward.sol";
import "./IGoMiningToken.sol";
import "./IMinterBurner.sol";
import "./IMarketingVoting.sol";

contract VECycleHelper is PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IGoMiningToken;

    IGoMiningToken public Token;
    IMinterBurner public MinterBurner;
    IMarketingVoting public MarketingVoting;

    uint256 public constant WEEK = 1 weeks;
    uint256 public constant DAY = 1 days;

    mapping(uint256 => bool) public daysTasksCompleted; // start of the day ts => done or not
    mapping(uint256 => bool) public weeksTasksCompleted; // start of the week (THU) => done or not


    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    event DailyTask(
        uint256 value,
        uint256 ts
    );

    event WeeklyTask(
        uint256 ts
    );

    function initialize(address _token, address _minterBurner, address _marketingVoting) initializer public {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_token != address(0), "MintReward: _token is zero address");
        require(_minterBurner != address(0), "MintReward: _minterBurner is zero address");
        require(_marketingVoting != address(0), "MintReward: _marketingVoting is zero address");

        Token = IGoMiningToken(_token);
        MinterBurner = IMinterBurner(_minterBurner);
        MarketingVoting = IMarketingVoting(_marketingVoting);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(CALLER_ROLE, _msgSender());
        _grantRole(CONFIGURATOR_ROLE, _msgSender());


    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    function makeDailyTasks(uint256 value, uint256 ts) external onlyRole(CALLER_ROLE) nonReentrant whenNotPaused {

        require(value > 0, "VECycleHelper: Cannot deposit 0 tokens");
        require(Token.balanceOf(address(this)) >= value, "VECycleHelper: Not enough tokens");

        uint256 tsd = (ts / DAY) * DAY;

        require(!daysTasksCompleted[tsd], "VECycleHelper: daily tasks have already done");

        Token.approve(address(MinterBurner), value);
        MinterBurner.increaseAmount(value);
        MinterBurner.spendForMaintenances(address(this), value);

        daysTasksCompleted[tsd] = true;

        emit DailyTask(value, tsd);
    }


    function makeWeeklyTasks(uint256 ts) external onlyRole(CALLER_ROLE) nonReentrant whenNotPaused {
        uint256 tsw = (ts / WEEK) * WEEK;

        require(!weeksTasksCompleted[tsw], "VECycleHelper: weekly tasks have already done");

        MinterBurner.burnAndMint();

        weeksTasksCompleted[tsw] = true;

        emit WeeklyTask(tsw);
    }


    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

}
