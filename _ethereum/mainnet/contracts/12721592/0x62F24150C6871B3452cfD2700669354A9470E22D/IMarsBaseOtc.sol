// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IMarsBaseOtc {
    enum OrderTypeInfo {error, buyType, sellType}

    struct OrderInfo {
        address owner;
        address token;
        uint256 amountOfToken;
        uint256 expirationDate;
        uint16 discount; // 10 is 1%, max value 1'000
        bool isCancelled;
        bool isSwapped;
        bool isManual;
        OrderTypeInfo orderType;
    }
    struct OrdersBidInfo {
        address investor;
        address investedToken;
        uint256 amountInvested;
    }
    struct BrokerInfo {
        address broker;
        uint256 percents;
    }

    function createOrder(
        bytes32 _id,
        address _token,
        uint256 _amountOfToken,
        uint256 _expirationDate,
        address _ownerBroker,
        uint256 _ownerBrokerPerc,
        address _usersBroker,
        uint256 _usersBrokerPerc,
        uint16 _discount,
        OrderTypeInfo orderType,
        bool _isManual
    ) external;

    function orderDeposit(
        bytes32 _id,
        address _token,
        uint256 _amount
    ) external payable;

    function cancel(bytes32 _id) external;

    function makeSwap(bytes32 _id, OrdersBidInfo[] memory distribution)
        external;

    function makeSwapOrderOwner(bytes32 _id, uint256 orderIndex) external;

    function cancelBid(bytes32 _id, uint256 bidIndex) external;
}
