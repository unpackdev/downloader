// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./PaymentStorage.sol";
import "./AccessControlStorage.sol";
import "./Structs.sol";

contract ManagerFacet {

    error AddressIsZero();
    error InvalidAmount();
    error InvalidBaseFee();
    error InvalidFeeDiscount();
    error InvalidServiceID();
    error UnauthService();
    error ServiceTerminated();
    error InsufficientBalance();

    event BaseFeeChanged(uint feeRatio);
    event FeeDiscountChanged(address user, uint discountRatio);
    event TokenRegisterChanged(address addr, bool enable);
    event TemplateAddressChanged(address addr);
    event WithdrawProtocolIncome(address indexed caller, address token, address to, uint amount);
    event TerminateService(bytes32 indexed id, address indexed caller, address buyer, address seller, address token, uint amount, uint remaining, uint fee);

    function isRegisteredToken(address _token) external view returns (bool) {
        return PaymentStorage.layout().registeredToken[_token];
    }

    function getTemplateAddress() external view returns (address) {
        return PaymentStorage.layout().template;
    }

    function getBaseFee() external view returns (uint) {
        return PaymentStorage.layout().baseFee;
    }

    function getProtocolIncome(address _token) external view returns (uint) {
        return PaymentStorage.layout().protocolIncome[_token];
    }

    function registerToken(address _token) external {
        if (_token == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();
        
        PaymentStorage.layout().registeredToken[_token] = true;
        emit TokenRegisterChanged(_token, true);
    }

    function unregisterToken(address _token) external {
        if (_token == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();
        
        PaymentStorage.layout().registeredToken[_token] = false;
        emit TokenRegisterChanged(_token, false);
    }

    function setTemplateAddress(address _addr) external {
        if (_addr == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsOwner();

        PaymentStorage.layout().template = _addr;
        emit TemplateAddressChanged(_addr);
    }

    function setBaseFee(uint _feeRatio) external {
        if (_feeRatio > 100000) revert InvalidBaseFee();
        AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);

        PaymentStorage.layout().baseFee = _feeRatio;
        emit BaseFeeChanged(_feeRatio);
    }

    function setUserFeeDiscount(address _user, uint _discount) external {
        if (_user == address(0)) revert AddressIsZero();
        if (_discount > 100) revert InvalidFeeDiscount();
        AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);

        PaymentStorage.layout().userAccounts[_user].feeDiscount = _discount;
        emit FeeDiscountChanged(_user, _discount);
    }

    function withdrawProtocolIncome(address _token, address _to, uint _amount) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_to == address(0)) revert AddressIsZero();
        if (_amount == 0) revert InvalidAmount();
        AccessControlStorage.enforceIsOwner();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (_amount > layout.protocolIncome[_token]) revert InsufficientBalance();

        unchecked {
            layout.protocolIncome[_token] -= _amount;
        }
        IERC20(_token).transfer(_to, _amount);

        emit WithdrawProtocolIncome(msg.sender, _token, _to, _amount);
    }

    function terminateByBusiness(bytes32 _id, uint _amount) external {
        _terminate(_id, _amount, false);
    }

    function terminateByManager(bytes32 _id, uint _amount) external {
        _terminate(_id, _amount, true);
    }

    function _terminate(
        bytes32 _id,
        uint _amount,
        bool _force
    ) internal {
        if (_id == bytes32(0)) revert InvalidServiceID();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        Service storage service = layout.subscription[_id];

        if (service.terminated) revert ServiceTerminated();

        if (_force) {
            AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);
        } else {
            if (service.seller != msg.sender) revert UnauthService();
        }

        // avoid mutating original value
        uint deposit = service.security;
        if (deposit < _amount) revert InsufficientBalance();

        uint fee;
        uint remaining;
        address token = service.token;
        // Overflow not possible: the sum of all balances is capped by usdt totalSupply, and the sum is preserved by
        unchecked {
            if (_amount == 0) {
                layout.userAccounts[service.buyer].balances[token] += deposit;
                service.security = 0;
            } else {
                remaining = deposit - _amount;
                fee = PaymentStorage.calculateServiceFee(service.seller, _amount);
                layout.userAccounts[service.buyer].balances[token] += remaining;
                layout.userAccounts[service.seller].balances[token] += (_amount - fee);
                layout.protocolIncome[token] += fee;
                service.security = 0;
            }
        }
        service.terminated = true;
        
        emit TerminateService(_id, msg.sender, service.buyer, service.seller, token, _amount, remaining, fee);
    }

}