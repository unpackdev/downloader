pragma solidity ^0.8.10;

interface IAssetConverter {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct ComplexRouteUpdate {
        address source;
        address destination;
        address[] complexRoutes;
    }

    struct RouteData {
        address converter;
        uint256 maxAllowedSlippage;
    }

    struct RouteDataUpdate {
        address source;
        address destination;
        RouteData data;
    }

    function complexRoutes(address source, address destination) external view returns (address[] memory);
    function owner() external view returns (address);
    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
    function pricesOracle() external view returns (address);
    function renounceOwnership() external;
    function routes(address source, address destination) external view returns (RouteData memory);
    function swap(address source, address destination, uint256 amountIn) external returns (uint256);
    function transferOwnership(address newOwner) external;
    function updateComplexRoutes(ComplexRouteUpdate[] memory updates) external;
    function updateRoutes(RouteDataUpdate[] memory updates) external;
}

