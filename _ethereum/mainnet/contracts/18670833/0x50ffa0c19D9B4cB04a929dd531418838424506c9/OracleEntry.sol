// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./IOracleEntry.sol";
import "./IOracleAdapter.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./Errors.sol";

contract OracleEntry is IOracleEntry {
    uint8 public constant TARGET_DECIMALS = 18;

    IAddressManager public addressManager;

    mapping(DataSource => address) public adapters;

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    constructor(IAddressManager _addressManager) {
        addressManager = _addressManager;
    }

    function getSinglePrice(
        address asset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128) {
        return _getAdapter(dataSource).getSinglePrice(asset, timestamp);
    }

    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128) {
        return
            _getAdapter(dataSource).getPrice(baseAsset, quoteAsset, timestamp);
    }

    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external onlyCegaAdmin {
        adapters[dataSource] = adapter;

        emit DataSourceAdapterSet(dataSource, adapter);
    }

    function getTargetDecimals() external pure returns (uint8) {
        return TARGET_DECIMALS;
    }

    function _getAdapter(
        DataSource dataSource
    ) private view returns (IOracleAdapter) {
        address adapter = adapters[dataSource];
        require(adapter != address(0), Errors.NOT_AVAILABLE_DATA_SOURCE);
        return IOracleAdapter(adapter);
    }
}
