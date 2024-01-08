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

    bool public isInitialized = false;
    uint256 public startDate;
    uint256 public endDate;

    mapping(address => bool) public whitelisted;
    mapping(address => mapping(address => uint256)) public info;

    function whitelistToken(address token) external onlyOwner {
        require(token != address(0), "invalid address");
        whitelisted[token] = true;
    }

    function initialize(uint256 endDateInSeconds) external onlyOwner {
        require(!isInitialized, "contract already initialized");
        require(endDateInSeconds > 3500, "min end date error"); //89 days

        startDate = block.timestamp;
        endDate = startDate.add(endDateInSeconds);
        isInitialized = true;
    }

    function deposit(address token, uint256 amount) external nonReentrant {
        require(isInitialized, "contract not initialized");
        require(whitelisted[token] == true, "token not whitelisted");
        require(block.timestamp < endDate, "lock period is over");

        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            amount
        );

        info[msg.sender][token] = info[msg.sender][token].add(amount);
        emit Deposit(msg.sender, token, block.timestamp, amount);
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
