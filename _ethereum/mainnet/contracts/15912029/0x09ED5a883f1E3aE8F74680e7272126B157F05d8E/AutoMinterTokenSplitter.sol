// SPDX-License-Identifier: UNLICENSED

import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract AutoMinterTokenSplitter is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address internal paymentToken;
    uint256 internal _totalShares;
    uint256 internal _totalTokenReleased;
    address[] internal _payees;
    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _tokenReleased;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    
    constructor() {}
    
    function initialize() public initializer {
        _transferOwnership(msg.sender);
    }
    
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function addPayee(address account_, uint256 shares_) onlyOwner() public {
        _addPayee(account_, shares_);
    }
    
    function _addPayee(address account, uint256 shares_) internal {
        require(
            account != address(0),
            "AutoMinterTokenSplitter: account is the zero address"
        );
        require(shares_ > 0, "AutoMinterTokenSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "AutoMinterTokenSplitter: account already has shares"
        );
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        
        emit PayeeAdded(account, shares_);
    }
    
    function release(address account) public virtual {
        require(
            _shares[account] > 0, "AutoMinterTokenSplitter: account has no shares"
        );
        
        uint256 tokenTotalReceived = IERC20Upgradeable(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
        
        uint256 payment = (tokenTotalReceived * _shares[account]) / _totalShares - _tokenReleased[account];
        
        require(payment != 0, "AutoMinterTokenSplitter: account is not due payment");
        _tokenReleased[account] = _tokenReleased[account] + payment;
        _totalTokenReleased = _totalTokenReleased + payment;
        IERC20Upgradeable(paymentToken).safeTransfer(account, payment);
        
        emit PaymentReleased(account, payment);
    }
    
    /**
     * @notice Set payment token address
     * @dev Set payment token address
     */
    function setPaymentToken(address paymentToken_) onlyOwner() public
    {
        paymentToken = paymentToken_;
    }
}