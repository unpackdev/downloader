// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IOilerOptionsRouter.sol";

interface IOilerRegistry {
    function PUT() external view returns (uint256);

    function CALL() external view returns (uint256);

    function activeOptions(bytes32 _type) external view returns (address[2] memory);

    function archivedOptions(bytes32 _type, uint256 _index) external view returns (address);

    function optionTypes(uint256 _index) external view returns (bytes32);

    function factories(bytes32 _optionType) external view returns (address);

    function optionsRouter() external view returns (IOilerOptionsRouter);

    function getOptionTypesLength() external view returns (uint256);

    function getOptionTypeAt(uint256 _index) external view returns (bytes32);

    function getArchivedOptionsLength(string memory _optionType) external view returns (uint256);

    function getArchivedOptionsLength(bytes32 _optionType) external view returns (uint256);

    function getOptionTypeFactory(string memory _optionType) external view returns (address);

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory);

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory);

    function registerFactory(address factory) external;

    function setOptionsTypeFactory(string memory _optionType, address _factory) external;

    function registerOption(address _optionAddress, string memory _optionType) external;

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external;
}
