// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./IYLDROracle.sol";
import "./IPoolAddressesProvider.sol";
import "./IConverter.sol";
import "./IAssetConverter.sol";

/// @author YLDR <admin@apyflow.com>
contract AssetConverter is IAssetConverter, Ownable {
    using SafeERC20 for IERC20;

    IPoolAddressesProvider private immutable addressesProvider;
    mapping(address => mapping(address => IConverter)) private _routes;
    mapping(address => mapping(address => address[])) private _complexRoutes;

    constructor(IPoolAddressesProvider _addressesProvider) Ownable(msg.sender) {
        addressesProvider = _addressesProvider;
    }

    function routes(address source, address destination) public view returns (IConverter) {
        return _routes[source][destination];
    }

    function complexRoutes(address source, address destination) public view returns (address[] memory) {
        return _complexRoutes[source][destination];
    }

    function updateRoutes(RouteConverterUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _routes[updates[i].source][updates[i].destination] = updates[i].converter;
        }
    }

    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            _complexRoutes[updates[i].source][updates[i].destination] = updates[i].complexRoutes;
        }
    }

    function _checkSlippage(
        address source,
        address destination,
        uint256 amountIn,
        uint256 amountOut,
        uint256 maxSlippage
    ) internal view returns (bool) {
        // If amountIn is low enough, than fee substraction may substract 1
        // And in case in low amountIn this can make big difference
        amountIn -= 1;

        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());
        uint256 sourceUSDPrice = oracle.getAssetPrice(source);
        uint256 destinationUSDPrice = oracle.getAssetPrice(destination);

        uint256 sourceUSDValue = (amountIn * sourceUSDPrice) / (10 ** IERC20Metadata(source).decimals());
        uint256 expected = (sourceUSDValue * (10 ** IERC20Metadata(destination).decimals())) / destinationUSDPrice;
        return (amountOut >= (expected * (10000 - maxSlippage)) / 10000);
    }

    function _getRoute(address source, address destination)
        internal
        view
        returns (address[] memory tokens, IConverter[] memory converters)
    {
        uint256 complexRoutesLength = _complexRoutes[source][destination].length;
        tokens = new address[](2 + complexRoutesLength);
        converters = new IConverter[](tokens.length - 1);
        tokens[0] = source;
        for (uint256 i = 0; i < complexRoutesLength; i++) {
            tokens[i + 1] = _complexRoutes[source][destination][i];
        }
        tokens[tokens.length - 1] = destination;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            converters[i] = _routes[tokens[i]][tokens[i + 1]];
            require(address(converters[i]) != address(0), "AssetConverter: No converter specified for the route");
        }
    }

    function swap(address source, address destination, uint256 amountIn, uint256 maxSlippage)
        external
        returns (uint256)
    {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        IERC20(source).safeTransferFrom(msg.sender, address(converters[0]), amountIn);
        uint256 currentAmount = amountIn;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            if (currentAmount == 0) {
                break;
            }

            address to = i < tokens.length - 2 ? address(converters[i + 1]) : msg.sender;
            currentAmount = converters[i].swap(tokens[i], tokens[i + 1], currentAmount, to);
        }

        uint256 amountOut = currentAmount;

        if (!_checkSlippage(source, destination, amountIn, amountOut, maxSlippage)) {
            revert SlippageTooBig(amountIn, amountOut);
        }

        return amountOut;
    }

    function previewSwap(address source, address destination, uint256 value) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            IConverter converter = converters[i];
            value = converter.previewSwap(tokens[i], tokens[i + 1], value);
        }
        return value;
    }
}
