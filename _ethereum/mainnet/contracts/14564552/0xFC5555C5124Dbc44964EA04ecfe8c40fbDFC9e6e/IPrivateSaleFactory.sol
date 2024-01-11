//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSaleFactory {
    function receiverAddress() external view returns (address);

    function devAddress() external view returns (address);

    function devFee() external view returns (uint256);

    function implementation() external view returns (address);

    function getPrivateSale(string memory name) external view returns (address);

    function privateSales(uint256 index) external view returns (address);

    function initialize(address receiverAddress, address implementation)
        external;

    function lenPrivateSales() external view returns (uint256);

    function createPrivateSale(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minAmount
    ) external returns (address);

    function addToWhitelist(string calldata name, address[] calldata addresses)
        external;

    function removeFromWhitelist(
        string calldata name,
        address[] calldata addresses
    ) external;

    function validateUsers(string calldata name, address[] calldata addresses)
        external;

    function claim(string calldata name) external;

    function endSale(string calldata name) external;

    function setImplemention(address implementation) external;

    function setReceiverAddress(address receiver) external;

    function setDevAddress(address dev) external;

    function setDevFee(uint256 devFee) external;

    function emergencyWithdraw(string calldata name) external;
}
