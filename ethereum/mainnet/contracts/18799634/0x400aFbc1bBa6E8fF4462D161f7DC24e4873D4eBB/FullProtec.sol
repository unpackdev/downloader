// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IScramble.sol";
import "./IWhite.sol";
import "./IScrambleChef.sol";

pragma solidity 0.8.19;

contract FullProtec is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
    }

    IScramble public scramble;
    IWhite public white;
    IScrambleChef public chef;
    uint256 public lockDuration;
    uint256 public totalStaked;
    bool public depositsEnabled;
    bool public emergencyWithdrawEnabled;
    // Info of each user.
    mapping(address => UserInfo) public userInfo;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event QuickWithdraw(address indexed user, uint256 amount, uint256 taxPaid);
    event StartSlowWithdraw(address indexed user, uint256 amount, uint256 unlockTimestamp);
    event EmergencywWithdraw(address indexed user, uint256 amount);
    event FinishSlowWithdraw(address indexed user, uint256 amount);
    event LogSetLockDuration(uint256 lockDuration);
    event LogSetDepositsEnabled(bool enabled);
    event LogSetEmergencyWithdrawEnabled(bool enabled);

    constructor(IScramble _scramble, IWhite _white, uint256 _lockDuration, bool _depositsEnabled) {
        scramble = _scramble;
        white = _white;
        lockDuration = _lockDuration;
        depositsEnabled = _depositsEnabled;
    }

    function setDepositsEnabled(bool _enabled) external onlyOwner {
        depositsEnabled = _enabled;
        emit LogSetDepositsEnabled(_enabled);
    }

    function setLockDuration(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
        emit LogSetLockDuration(_lockDuration);
    }

    function setEmergencyWithdrawEnabled(bool _enabled) external onlyOwner {
        emergencyWithdrawEnabled = _enabled;
        emit LogSetEmergencyWithdrawEnabled(_enabled);
    }

    function deposit(uint256 _amount) external {
        require(depositsEnabled, "Deposits disabled");
        require(_amount > 0, "Invalid amount");

        UserInfo storage user = userInfo[msg.sender];

        require(user.lockEndedTimestamp == 0, "Can't deposit while in slow withdraw");

        IERC20(address(scramble)).safeTransferFrom(address(msg.sender), address(this), _amount);
        scramble.burn(_amount);

        white.mint(address(this), _amount);
        white.approve(address(chef), _amount);
        chef.deposit(0, _amount, msg.sender);

        totalStaked += _amount;
        user.amount += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function emergencyWithdraw(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        require(emergencyWithdrawEnabled, "Emergency withdraw disabled");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Invalid amount");

        user.amount -= _amount;
        totalStaked -= _amount;

        scramble.mint(address(msg.sender), _amount);
        chef.withdraw(0, _amount, msg.sender);
        white.burn(_amount);

        user.lockEndedTimestamp = 0;

        emit EmergencywWithdraw(msg.sender, _amount);
    }

    function startSlowWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount > 0, "Nothing to withdraw");
        require(user.lockEndedTimestamp == 0, "You already started slow withdraw");

        user.lockEndedTimestamp = block.timestamp + lockDuration;

        emit StartSlowWithdraw(msg.sender, user.amount, user.lockEndedTimestamp);
    }

    function finishSlowWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount > 0, "Nothing to withdraw");
        require(user.lockEndedTimestamp != 0, "Slow withdraw not started");
        require(user.lockEndedTimestamp <= block.timestamp, "Still locked");

        uint256 _amount = user.amount;

        user.amount -= _amount;
        totalStaked -= _amount;
        user.lockEndedTimestamp = 0;

        scramble.mint(address(msg.sender), _amount);
        chef.withdraw(0, _amount, msg.sender);
        white.burn(_amount);

        emit FinishSlowWithdraw(msg.sender, user.amount);
    }

    function quickWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount > 0, "Nothing to withdraw");
        require(user.lockEndedTimestamp == 0, "You already started slow withdraw");

        uint256 _amount = user.amount;
        uint256 tax = this.getQuickWithdrawTax(msg.sender);

        user.amount -= _amount;
        totalStaked -= _amount;

        scramble.mint(address(msg.sender), _amount - tax);
        scramble.mint(address(0), tax);
        chef.withdraw(0, _amount, msg.sender);
        white.burn(_amount);

        emit QuickWithdraw(msg.sender, _amount, tax);
    }

    function getQuickWithdrawTax(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return ((user.amount * this.getPercentSupplyStaked()) / 1e18 / 100);
    }

    // Used in dynamic debase calculation
    function getPercentSupplyStaked() external view returns (uint256) {
        return ((totalStaked * 1e18) / (scramble.INIT_SUPPLY())) * 100;
    }

    function setChef(address chefAddress) public onlyOwner {
        chef = IScrambleChef(chefAddress);
    }
}
