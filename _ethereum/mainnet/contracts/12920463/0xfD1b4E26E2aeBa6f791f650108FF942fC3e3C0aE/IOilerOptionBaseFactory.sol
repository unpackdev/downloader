// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IOilerOptionBaseFactory {
    function optionLogicImplementation() external view returns (address);

    function isClone(address _query) external view returns (bool);

    function createOption(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external returns (address optionAddress);
}
