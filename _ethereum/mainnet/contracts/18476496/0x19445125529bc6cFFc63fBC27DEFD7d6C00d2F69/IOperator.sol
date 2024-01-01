// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getMaxDistributeIndex() external view returns (uint256);
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setPlugin(address plugin, bool isPlugin) external;
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
}
