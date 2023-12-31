// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./PaymentStorage.sol";
import "./Structs.sol";

contract AccountFacet {

    error AddressIsZero();
    error InvalidAmount();
    error InvalidToken();
    error InvalidServiceID();
    error UnauthService();
    error ServiceTerminated();
    error InsufficientBalance();

    event DepositBalance(address indexed caller, address indexed token, uint amount);
    event DepositSecurity(address indexed caller, address token, uint amount, bytes32 id);
    event WithdrawBalance(address indexed caller, address indexed token, address indexed to, uint amount);
    event WithdrawSecurity(address indexed caller, address token, address indexed to, uint amount, bytes32 id);

    function getTokenBalance(address _user, address _token) external view returns (uint) {
        return PaymentStorage.layout().userAccounts[_user].balances[_token];
    }

    function getTokensBalance(address _user, address[] calldata _tokens) external view returns (uint[] memory) {
        Account storage account = PaymentStorage.layout().userAccounts[_user];
        uint len = _tokens.length;
        uint[] memory tokenBalance = new uint[](len);
        for (uint i; i < len; i++) {
            tokenBalance[i] = account.balances[_tokens[i]];
        }
        
        return tokenBalance;
    }

    function getUserFeeDiscount(address _user) external view returns (uint) {
        return PaymentStorage.layout().userAccounts[_user].feeDiscount;
    }

    function getUserAccount(address _user, address[] calldata _tokens) external view returns (uint, uint[] memory) {
        Account storage account = PaymentStorage.layout().userAccounts[_user];
        uint len = _tokens.length;
        uint[] memory tokenBalance = new uint[](len);
        for (uint i; i < len; i++) {
            tokenBalance[i] = account.balances[_tokens[i]];
        }
        
        return (
            account.feeDiscount,
            tokenBalance
        );
    }

    function getService(bytes32 _id) external view returns (Service memory) {
        return PaymentStorage.layout().subscription[_id];
    }

    function getWithdrawSecurityQuota(bytes32 _id) external view returns (uint) {
        return _withdrawSecurityQuota(_id);
    }

    function isTerminated(bytes32 _id) external view returns (bool) {
        return PaymentStorage.layout().subscription[_id].terminated;
    }

    function depositBalance(address _token, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (!layout.registeredToken[_token]) revert InvalidToken();
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Overflow not possible: the sum of all balances is capped by usdt totalSupply, and the sum is preserved by
        unchecked {
            layout.userAccounts[msg.sender].balances[_token] += _amount;
        }

        emit DepositBalance(msg.sender, _token, _amount);
    }

    function depositSecurity(bytes32 _id, uint _amount) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_amount == 0) revert InvalidAmount();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];
        if (service.terminated) revert ServiceTerminated();

        IERC20(service.token).transferFrom(msg.sender, address(this), _amount);
        service.security += _amount;

        emit DepositSecurity(msg.sender, service.token, _amount, _id);
    }

    function withdrawBalance(address _token, address _to, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Account storage account = layout.userAccounts[msg.sender];
        if (account.balances[_token] < _amount) revert InsufficientBalance();

        IERC20(_token).transfer(_to, _amount);
        unchecked {
            account.balances[_token] -= _amount;
        }

        emit WithdrawBalance(msg.sender, _token, _to, _amount);
    }

    function withdrawSecurity(bytes32 _id, address _to, uint _amount) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];
        if (service.buyer != msg.sender) revert UnauthService();
        if (service.terminated) revert ServiceTerminated();
        
        uint quota = _withdrawSecurityQuota(_id);
        if (quota < _amount) revert InsufficientBalance();
        IERC20(service.token).transfer(_to, _amount);

        unchecked {
            service.security -= _amount;
        }

        emit WithdrawSecurity(msg.sender, service.token, _to, _amount, _id);
    }

    function _withdrawSecurityQuota(bytes32 _id) internal view returns (uint) {
        Service memory service = PaymentStorage.layout().subscription[_id];
        unchecked {
            uint security = service.security;
            uint double = service.lastConsume * 2;
            return double < security ? security - double : 0;
        }
    }

}