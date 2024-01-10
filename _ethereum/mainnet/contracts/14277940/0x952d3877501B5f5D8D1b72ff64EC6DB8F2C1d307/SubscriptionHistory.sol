// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Context.sol";

abstract contract SubscriptionHistory is Ownable {
    event UpdateSubscriptionEntries(address account, uint256 startDate, uint256 endDate,uint256 orderId);
    struct SubscriptionInfo {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address subscriber;
        bool isToken;
        bool isETH;
        uint256 orderId;
    }

    struct OrderIdHistory {
        uint256 orderId;
    }
    mapping(address => OrderIdHistory[]) private _subscriberDetailsByAddress;
    mapping(address => SubscriptionInfo) private _activeSubscriptionByAddress;

    SubscriptionInfo[] internal _subscribers;

    constructor() {
        SubscriptionInfo memory zeroInfo = SubscriptionInfo(0, 0, 0, address(0),false, false,0);
        _subscribers.push(zeroInfo);
    }

    function addSubscriber(address subscriber, uint256 amount, uint256 startTime, uint256 endTime,bool isToken, bool isETH,uint256 orderId) internal returns (uint256 index) {
        index = _subscribers.length;
        SubscriptionInfo memory subsInfo = SubscriptionInfo(amount, startTime, endTime,subscriber, isToken,isETH,orderId);
        _subscribers.push(subsInfo);
        _activeSubscriptionByAddress[subscriber] = subsInfo;
        OrderIdHistory memory orderInfo = OrderIdHistory(orderId);
        _subscriberDetailsByAddress[subscriber].push(orderInfo);
        emit UpdateSubscriptionEntries(subscriber,startTime,endTime,orderId);
    }

    function getSubscriberByOrderId(uint256 orderId) public view returns(SubscriptionInfo memory subscriberInfo) {
        // if no data in map will get 0 index and zeroInfo.
        return _subscribers[orderId];
    }


    function getLastSubscribers(uint256 n) external view returns(SubscriptionInfo[] memory) {
        uint256 len = n > _subscribers.length ? _subscribers.length : n;

        SubscriptionInfo[] memory subInfo = new SubscriptionInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            subInfo[i] = _subscribers[_subscribers.length - i - 1];
        }

        return _subscribers;
    }

    function getActiveSubscriptionByAddress(address subscriber) external view returns(SubscriptionInfo memory) {
        return _activeSubscriptionByAddress[subscriber];
    }


    function getSubscriptionHistoryByAddres(address subscriber, uint256 n) external view returns(SubscriptionInfo[] memory) {
        uint256 len = n > _subscribers.length ? _subscribers.length : n;

        SubscriptionInfo[] memory subInfo = new SubscriptionInfo[](len);
        OrderIdHistory[] memory oIdHistory = _subscriberDetailsByAddress[subscriber];
        

        for (uint256 i = 0; i < oIdHistory.length; i++) {
            subInfo[i] = _subscribers[oIdHistory[i].orderId];
        }

        return subInfo;
    }

    function getSubscriptionOrderIdHistory(address subscriber) external view returns(OrderIdHistory[] memory) {
        return _subscriberDetailsByAddress[subscriber];
    }



}