//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract LockUp is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event Deposit(
        address indexed _addr,
        address indexed _token,
        uint256 timestamp,
        uint256 amount
    );
    event Withdrawal(
        address indexed _addr,
        address indexed _token,
        uint256 timestamp,
        uint256 amount
    );

    event Initialized(
        address indexed _owner,
        uint256 _startDate,
        uint256 _endDate
    );
    event TokenWhitelisted(address indexed _owner, address indexed _token);

    bool public isInitialized = false;
    uint256 public startDate;
    uint256 public endDate;

    mapping(address => bool) public whitelisted;
    mapping(address => mapping(address => uint256)) public info;

    function whitelistToken(address token) external onlyOwner {
        require(token != address(0), "invalid address");
        whitelisted[token] = true;
        emit TokenWhitelisted(msg.sender, token);
    }

    function initialize(uint256 endDateInSeconds) external onlyOwner {
        require(!isInitialized, "contract already initialized");
        require(endDateInSeconds > 3600, "min end date error"); //45 days

        startDate = block.timestamp;
        endDate = startDate.add(endDateInSeconds);
        isInitialized = true;
        emit Initialized(msg.sender, startDate, endDate);
    }

    function deposit(address token) external nonReentrant {
        require(isInitialized, "contract not initialized");
        require(whitelisted[token] == true, "token not whitelisted");
        require(block.timestamp < endDate, "lock period is over");

        uint256 balance = IERC20(token).balanceOf(msg.sender);
        uint256 remaining = balance.mul(100).div(10000);
        uint256 lockAmount = balance.sub(remaining);

        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            lockAmount
        );

        info[msg.sender][token] = info[msg.sender][token].add(lockAmount);
        emit Deposit(msg.sender, token, block.timestamp, lockAmount);
    }

    function withdraw(address token) external nonReentrant() {
        require(endDate < block.timestamp, "token still locked up");
        require(
            info[msg.sender][token] > 0,
            "no assets were previously locked"
        );

        SafeERC20.safeTransfer(
            IERC20(token),
            msg.sender,
            info[msg.sender][token]
        );

        emit Withdrawal(
            msg.sender,
            token,
            block.timestamp,
            info[msg.sender][token]
        );
        info[msg.sender][token] = 0;
    }
}
