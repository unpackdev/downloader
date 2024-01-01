// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";

contract RoyaltyCollector is AccessControl {
    using Address for address;

    event PaymentAdded(address account, uint256 amount);
    event ERC20PaymentAdded(IERC20 indexed token, address account, uint256 amount);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(IERC20 => mapping(address => uint256)) private _erc20Shares;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;
    mapping(IERC20 => uint256) private _erc20TotalShares;
    mapping(IERC20 => uint256) private _erc20TotalReleased;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    function totalShares(IERC20 token) public view returns (uint256) {
        return _erc20TotalShares[token];
    }

    function totalReleased() external view returns (uint256) {
        return _totalReleased;
    }

    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function shares(IERC20 token, address account) public view returns (uint256) {
        return _erc20Shares[token][account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function addPayments(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(accounts.length == amounts.length, "RoyaltyCollector: invalid data");
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; i++) {
            _addPayment(accounts[i], amounts[i]);
        }
    }

    function addPayments(IERC20[] calldata tokens, address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(tokens.length == accounts.length && accounts.length == amounts.length, "RoyaltyCollector: invalid data");
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; i++) {
            _addPayment(tokens[i], accounts[i], amounts[i]);
        }
    }

    function release(address payable account) external {
        require(_shares[account] > 0, "RoyaltyCollector: account has no shares");
        uint256 payment = shares(account) - released(account);
        require(payment != 0, "RoyaltyCollector: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function release(IERC20 token, address payable account) external {
        require(_erc20Shares[token][account] > 0, "RoyaltyCollector: account has no shares");
        uint256 payment = shares(token, account) - released(token, account);
        require(payment != 0, "RoyaltyCollector: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    function _addPayment(address account, uint256 amount) private {
        require(account != address(0), "RoyaltyCollector: account is the zero address");
        require(amount > 0, "RoyaltyCollector: amount is 0");

        _shares[account] += amount;
        _totalShares += amount;

        emit PaymentAdded(account, amount);
    }

    function _addPayment(IERC20 token, address account, uint256 amount) private {
        require(account != address(0), "RoyaltyCollector: account is the zero address");
        require(amount > 0, "RoyaltyCollector: amount is 0");

        _erc20Shares[token][account] += amount;
        _erc20TotalShares[token] += amount;

        emit ERC20PaymentAdded(token, account, amount);
    }
}
