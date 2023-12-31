// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Clones.sol";
import "./PaymentStorage.sol";
import "./AccessControlStorage.sol";
import "./ITemplate.sol";
import "./Structs.sol";

contract OrderFacet {

    error InvalidAmount();
    error InvalidToken();
    error InvalidServiceID();
    error AddressIsZero();
    error ArrayMismatch();

    event SubscribeService(bytes32 indexed id, address buyer, address seller, address token, uint security);
    event SettlementAssets(bytes32 indexed id, address payer, address receiver, address token, uint amount, uint fee);
    event SubscriptionBilling(bytes32[] ids, uint[] amounts, uint[] fees);

    function getPredictAddress(bytes32 _id) external view returns (address) {
        return Clones.predictDeterministicAddress(PaymentStorage.layout().template, _id);
    }

    function estimateServiceFee(uint _amount) external view returns (uint) {
        if (_amount == 0) return 0;
        return PaymentStorage.calculateServiceFee(msg.sender, _amount);
    }

    function subscribe(bytes32 _id, address _token, address _buyer, address _seller) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_token == address(0)) revert AddressIsZero();
        if (_buyer == address(0)) revert AddressIsZero();
        if (_seller == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);

        ITemplate template = ITemplate(Clones.cloneDeterministic(PaymentStorage.layout().template, _id));
        uint amount = template.withdrawToken(_token, address(this));
        _subscribe(_id, _token, _buyer, _seller, amount);
    }

    function settle(bytes32 _id, address _token, address _payer, address _receiver) external {
        if (_id == bytes32(0)) revert InvalidServiceID();
        if (_token == address(0)) revert AddressIsZero();
        if (_payer == address(0)) revert AddressIsZero();
        if (_receiver == address(0)) revert AddressIsZero();
        AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);
        
        PaymentStorage.Layout storage layout = PaymentStorage.layout();

        ITemplate template = ITemplate(Clones.cloneDeterministic(layout.template, _id));
        uint amount = template.withdrawToken(_token, address(this));
        uint fee = PaymentStorage.calculateServiceFee(_receiver, amount);

        unchecked {
            layout.userAccounts[_receiver].balances[_token] += (amount - fee);
            layout.protocolIncome[_token] += fee;
        }

        emit SettlementAssets(_id, _payer, _receiver, _token, amount, fee);
    }

    function billing(
        bytes32[] calldata _ids,
        uint[] calldata _amounts
    ) external {
        AccessControlStorage.enforceIsRole(AccessControlStorage.MANAGER_ROLE);

        uint len = _ids.length;
        if (len != _amounts.length) revert ArrayMismatch();

        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        uint userBalance;
        uint userSecurity;
        uint remainingAmount;

        bytes32[] memory subIds = new bytes32[](len);
        uint[] memory bills = new uint[](len);
        uint[] memory fees = new uint[](len);
        
        unchecked {
            for (uint i; i < len; ) {
                bytes32 id = _ids[i];
                if (id == bytes32(0)) revert InvalidServiceID();

                Service storage service = layout.subscription[id];
                if (service.buyer == address(0)) continue;
                address token = service.token;
                address seller = service.seller;
                uint amount = _amounts[i];
                if (amount == 0) revert InvalidAmount();
                uint fee = PaymentStorage.calculateServiceFee(seller, amount);

                Account storage buyerAccount = layout.userAccounts[service.buyer];
                userBalance = buyerAccount.balances[token];
                userSecurity = service.security;

                if (userBalance + userSecurity < amount) continue;

                if (userBalance < amount) {
                    remainingAmount = amount - userBalance;
                    buyerAccount.balances[token] = 0;
                    service.security = userSecurity - remainingAmount;
                } else {
                    buyerAccount.balances[token] -= amount;
                }

                service.lastConsume = amount;
                layout.userAccounts[seller].balances[token] += (amount - fee);
                layout.protocolIncome[token] += fee;

                subIds[i] = id;
                bills[i] = amount;
                fees[i] = fee;

                ++i;
            }
        }

        emit SubscriptionBilling(subIds, bills, fees);
    }

    function _subscribe(
        bytes32 _id,
        address _token,
        address _buyer,
        address _seller,
        uint _amount
    ) internal {
        if (_amount == 0) revert InvalidAmount();
        PaymentStorage.Layout storage layout = PaymentStorage.layout();
        if (!layout.registeredToken[_token]) revert InvalidToken();

        Service storage service = layout.subscription[_id];
        service.token = _token;
        service.buyer = _buyer;
        service.seller = _seller;
        unchecked {
            service.security = _amount;
            service.lastConsume = _amount / 2;
        }
        
        emit SubscribeService(_id, _buyer, _seller, _token, _amount);
    }

}