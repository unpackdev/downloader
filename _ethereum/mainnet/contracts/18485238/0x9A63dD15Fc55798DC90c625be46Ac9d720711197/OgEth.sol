// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./AccessControl.sol";

interface ITRC20 {
    function transfer(address recipient, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract OgEth is AccessControl {
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    event LogDeposit(address indexed player, uint256 indexed order, uint256 indexed amount);
    event LogWithdraw(address indexed player, uint256 indexed order, uint256 indexed amount);
    event LogWithdrawProfit(address indexed maintainer, uint256 indexed amount);

    address public usdt;
    mapping(address => mapping(uint256 => uint256)) public deposits;
    mapping(address => mapping(uint256 => uint256)) public withdraws;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MAINTAINER_ROLE, _msgSender());
        _grantRole(ORACLE_ROLE, _msgSender());
    }

    function deposit(uint256 amount, uint256 order) external {
        ITRC20(usdt).transferFrom(_msgSender(), address(this), amount);
        deposits[_msgSender()][order] = amount;
        emit LogDeposit(_msgSender(), order, amount);
    }

    function withdraw(address player, uint256 order, uint256 amount) external onlyRole(ORACLE_ROLE) {
        ITRC20(usdt).transfer(player, amount);
        withdraws[player][order] = amount;
        emit LogWithdraw(player, order, amount);
    }

    function withdrawProfit(address token, uint256 amount) external onlyRole(MAINTAINER_ROLE) {
        ITRC20(token).transfer(_msgSender(), amount);
        emit LogWithdrawProfit(_msgSender(), amount);
    }

    function setUsdt(address _usdt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdt = _usdt;
    }
}