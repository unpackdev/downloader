// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./console.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./EquinoxINJ.sol";
import "./IPeggy.sol";

contract DepositManager is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public equinoxINJ;
    IERC20 public realINJ;
    IPeggy public peggy;

    uint256 public constant lockingPeriod = 21 days;

    mapping(address => uint256) public depositBalance;
    mapping(address => uint256) public depositUnlockTimestamp;

    bool public competitionEnded;

    event Withdrawal(address indexed staker, uint256 withdrawalAmount, uint256 withdrawalTimestamp);

    event Deposit(
        address indexed staker,
        address indexed destination,
        uint256 depositAmount,
        uint256 depositUnlockTimestamp,
        uint256 depositTimestamp
    );

    modifier onlyValidWithdrawal(uint256 withdrawalAmount) {
        require(withdrawalAmount > 0, "Cannot withdraw amount of 0");
        require(
            depositUnlockTimestamp[msg.sender] <= block.timestamp || competitionEnded,
            "Cannot withdraw before unlocking period pass if competition still active"
        );

        _;
    }

    constructor(
        IPeggy peggy_,
        IERC20 realINJ_,
        IERC20 equinoxINJ_
    ) public {
        peggy = peggy_;
        realINJ = realINJ_;
        equinoxINJ = IERC20(equinoxINJ_);
        equinoxINJ.approve(address(peggy), type(uint256).max);
    }

    function deposit(uint256 amount) external nonReentrant {
        _depositFor(amount, msg.sender);
    }

    function depositFor(uint256 amount, address destination) public nonReentrant {
        _depositFor(amount, destination);
    }

    function withdraw(uint256 withdrawalAmount) external nonReentrant onlyValidWithdrawal(withdrawalAmount) {
        depositBalance[msg.sender] = depositBalance[msg.sender].sub(withdrawalAmount, "Cannot withdraw more than deposits");

        realINJ.safeTransfer(msg.sender, withdrawalAmount);
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
    }

    function withdrawAll() external nonReentrant onlyValidWithdrawal(depositBalance[msg.sender]) {
        uint256 withdrawalAmount = depositBalance[msg.sender];
        depositBalance[msg.sender] = 0;

        realINJ.safeTransfer(msg.sender, withdrawalAmount);
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
    }

    function endCompetition() external onlyOwner {
        competitionEnded = true;
    }

    function updatePeggy(IPeggy peggy_) external onlyOwner {
        peggy = peggy_;
        equinoxINJ.approve(address(peggy), type(uint256).max);
    }

    function _depositFor(uint256 amount, address destination) internal {
        require(amount > 0, "Cannot deposit amount of 0");
        require(!competitionEnded, "Cannot deposit on inactive competition");

        realINJ.safeTransferFrom(msg.sender, address(this), amount);
        peggy.sendToCosmos(address(equinoxINJ), destination, amount);

        depositBalance[msg.sender] = depositBalance[msg.sender].add(amount);
        depositUnlockTimestamp[msg.sender] = block.timestamp.add(lockingPeriod);

        emit Deposit(msg.sender, destination, amount, depositUnlockTimestamp[msg.sender], block.timestamp);
    }
}
