// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactoryClone {
    function fees() external view returns (uint256);

    function feesAddress() external view returns (address);

    event TokenCreated(
        string name,
        string symbol,
        string baseTokenURI,
        address indexed _contract
    );
    event FeesAddressChanged(address indexed to);
    event FeesUpdated(uint256 amount);
    event createPriceUpdated(uint256 amount);
}
