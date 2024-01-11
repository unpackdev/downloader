//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Wallet
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

error ZeroAddress();
error InvalidAmount();
error ExceededAmount();
error NotAllowedSender();
error NotAllowedAction();

contract LL420Wallet is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    struct UserWallet {
        uint256 balance;
    }

    mapping(address => UserWallet) public wallets;
    mapping(address => bool) public permissioned;
    bool public selfWithdrawAllowed;
    address public highTokenAddress;

    event Deposit(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event WithdrawToPoint(address indexed _user, uint256 _amount, uint256 _timestamp);
    event WithdrawToWallet(address indexed _user, uint256 _amount);

    modifier onlyAllowed() {
        if (permissioned[_msgSender()] == false) revert NotAllowedSender();
        _;
    }

    function initialize() external initializer {
        __Context_init();
        __Ownable_init();

        allowAddress(_msgSender(), true);
    }

    function deposit(address _user, uint256 _amount) external onlyAllowed {
        _deposit(_user, _amount);
    }

    function withdraw(address _user, uint256 _amount) external onlyAllowed {
        _withdraw(_user, _amount);
    }

    function balance(address _user) external view returns (uint256) {
        return wallets[_user].balance;
    }

    function withdraw(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);
    }

    function withdrawToPoint(uint256 _amount) external {
        if (selfWithdrawAllowed == false) revert NotAllowedAction();

        _withdraw(_msgSender(), _amount);

        emit WithdrawToPoint(_msgSender(), _amount, block.timestamp);
    }

    function withdrawToWallet(uint256 _amount) external {
        if (_msgSender() == address(0) || highTokenAddress == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();
        if (wallets[_msgSender()].balance < _amount) revert ExceededAmount();

        wallets[_msgSender()].balance -= _amount;

        IERC20Upgradeable(highTokenAddress).safeTransferFrom(address(this), _msgSender(), _amount);

        emit WithdrawToWallet(_msgSender(), _amount);
    }

    function allowAddress(address _user, bool _allowed) public onlyOwner {
        if (_user == address(0)) revert ZeroAddress();

        permissioned[_user] = _allowed;
    }

    function setHighToken(address _address) external onlyOwner {
        highTokenAddress = _address;
    }

    function allowSelfWithdraw(bool _enable) public onlyOwner {
        selfWithdrawAllowed = _enable;
    }

    function _deposit(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();

        wallets[_user].balance += _amount;

        emit Deposit(_user, _amount);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        if (_user == address(0)) revert ZeroAddress();
        if (_amount <= 0) revert InvalidAmount();
        if (wallets[_user].balance < _amount) revert ExceededAmount();

        wallets[_user].balance -= _amount;

        emit Withdraw(_user, _amount);
    }
}
