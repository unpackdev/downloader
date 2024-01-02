// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "./IConverter.sol";

/// @author YLDR <admin@apyflow.com>
interface IAssetConverter {
    error SlippageTooBig(uint256 amountIn, uint256 amountOut);

    struct RouteConverterUpdate {
        address source;
        address destination;
        IConverter converter;
    }

    struct ComplexRouteUpdate {
        address source;
        address destination;
        address[] complexRoutes;
    }

    function routes(address, address) external view returns (IConverter);
    function complexRoutes(address source, address destination) external view returns (address[] memory);

    function updateRoutes(RouteConverterUpdate[] calldata updates) external;
    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) external;

    function swap(address source, address destination, uint256 amountIn, uint256 maxSlippage)
        external
        returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}
