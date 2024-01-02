// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Multicall.sol";

contract Orb3BridgeRouter is Ownable, Multicall {

    mapping(address => bool) public AVAILABLE_TOKENS;

    uint256 public DEFAULT_CODE_ID = 9009;
    uint256 public MIN_DEPOSIT_AMOUNT = 0.01 ether;
    mapping(address => uint256) public MIN_DEPOSIT_TOKEN_AMOUNT;

    event Deposit(address from, address to, address token, uint256 amount, uint256 code);
    event Transfer(address from, address to, address token, uint256 amount);

    constructor() {
    }

    function charge() external payable {}

    receive() external payable {
        require(msg.value >= MIN_DEPOSIT_AMOUNT, "Insufficient Amount");

        emit Deposit(msg.sender, msg.sender, address(0), msg.value, DEFAULT_CODE_ID);
    }

    function deposit(address recipient, uint256 code) external payable {
        require(msg.value >= MIN_DEPOSIT_AMOUNT, "Insufficient Amount");

        emit Deposit(msg.sender, recipient, address(0), msg.value, code);
    }

    function depositToken(address token, address recipient, uint256 amount, uint256 code) external {
        require(AVAILABLE_TOKENS[token], "Unavaliable Deposit Token");
        require(amount >= MIN_DEPOSIT_TOKEN_AMOUNT[token], "Insufficient Token Amount");
        
        bool success = IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        
        require(success, "Deposit Failed");

        emit Deposit(msg.sender, recipient, token, amount, code);
    }

    function transfer(address token, address sender, address recipient, uint256 amount) external onlyOwner {
        if (token != address(0)) {
            bool success = IERC20(token).transfer(
                recipient,
                amount
            );
            require(success, "Transfer Failed");
        } else {
            payable(recipient).transfer(amount);
        }

        emit Transfer(sender, recipient, token, amount);
    }

    function setAvailable(address token, bool available) external onlyOwner {
        AVAILABLE_TOKENS[token] = available;
    }

    function setMinDepositAmount(uint256 min) external onlyOwner {
        MIN_DEPOSIT_AMOUNT = min;
    }

    function setDefaultCode(uint256 code) external onlyOwner {
        DEFAULT_CODE_ID = code;
    }

    function setMinDepositTokenAmount(address token, uint256 min) external onlyOwner {
        MIN_DEPOSIT_TOKEN_AMOUNT[token] = min;
    }

    function withdraw(address token) external onlyOwner {
        if (token != address(0)) {
            bool success = IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
            require(success, "Withdraw Failed");
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

}