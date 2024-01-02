// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IBeaconProxyController {
    error NoBeaconProxyContract();
    error InvalidProxyContract();

    event BeaconProxyUpdated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed newImplementationAddress,
        address oldImplementationAddress
    );

    function getBeaconProxyAddress(bytes32 beaconName) external view returns (address);

    function setFutureValueVaultImpl(address newImpl) external;

    function setLendingMarketImpl(address newImpl) external;

    function deployFutureValueVault() external returns (address futureValueVault);

    function deployLendingMarket(
        bytes32 ccy,
        uint256 orderFeeRate,
        uint256 cbLimitRange
    ) external returns (address market);
}
