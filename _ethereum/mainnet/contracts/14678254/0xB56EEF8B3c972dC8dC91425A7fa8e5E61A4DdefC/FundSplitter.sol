// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract FundSplitter is Ownable {
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    event PaymentReceived(address from, uint256 amount);

    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function releasable(address account) public view returns (uint256) {
        return _releasable(account, address(this).balance + totalReleased(), released(account));
    }

    function releasable(IERC20 token, address account) public view returns (uint256) {
        return _releasable(account, token.balanceOf(address(this)) + totalReleased(token), released(token, account));
    }

    function release(address payable account) external {
        require(_shares[account] > 0, "Account has no shares");

        uint256 payment = releasable(account);
        require(payment != 0, "Account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);

        emit PaymentReleased(account, payment);
    }

    function release(IERC20 token, address account) external {
        require(_shares[account] > 0, "Account has no shares");

        uint256 payment = releasable(token, account);
        require(payment != 0, "Account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);

        emit ERC20PaymentReleased(token, account, payment);
    }

    function addPayee(address account, uint256 shares_) external onlyOwner {
        require(account != address(0), "Account is the zero address");
        require(shares_ > 0, "Shares are 0");
        require(_shares[account] == 0, "Account already has shares");

        _shares[account] = shares_;
        _totalShares += shares_;

        emit PayeeAdded(account, shares_);
    }

    function removePayee(address account) external onlyOwner {
        require(account != address(0), "Account is the zero address");
        require(_shares[account] > 0, "Account has no shares");

        uint256 shares_ = _shares[account];
        _totalShares -= shares_;

        delete _shares[account];

        emit PayeeRemoved(account, shares_);
    }

    function _releasable(address account, uint256 totalReceived, uint256 alreadyReleased) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }
}
