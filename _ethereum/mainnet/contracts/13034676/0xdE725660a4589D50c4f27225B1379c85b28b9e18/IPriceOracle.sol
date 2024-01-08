// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory);
}
