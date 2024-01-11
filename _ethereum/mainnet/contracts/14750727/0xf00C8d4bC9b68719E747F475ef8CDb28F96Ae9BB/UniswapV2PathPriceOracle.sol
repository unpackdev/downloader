// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./ERC165.sol";

import "./FullMath.sol";
import "./FixedPoint112.sol";

import "./IUniswapV2PathPriceOracle.sol";

/// @title Uniswap path price oracle
/// @notice Contains logic for price calculation of asset which doesn't have a pair with a base asset
contract UniswapV2PathPriceOracle is IUniswapV2PathPriceOracle, ERC165 {
    using FullMath for uint;

    /// @notice List of assets to compose exchange pairs, where first element is input asset
    address[] internal path;
    /// @notice List of corresponding price oracles for provided path
    address[] internal oracles;

    constructor(address[] memory _path, address[] memory _oracles) {
        uint pathsCount = _path.length;
        require(pathsCount >= 2, "UniswapV2PathPriceOracle: PATH");
        require(_oracles.length == pathsCount - 1, "UniswapV2PathPriceOracle: ORACLES");

        path = _path;
        oracles = _oracles;
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint currentAssetPerBaseInUQ) {
        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            address asset = path[i + 1];
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).refreshedAssetPerBaseInUQ(asset),
                FixedPoint112.Q112
            );
            if (_asset == asset) {
                break;
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IUniswapV2PathPriceOracle
    function anatomy() external view override returns (address[] memory _path, address[] memory _oracles) {
        _path = path;
        _oracles = oracles;
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint currentAssetPerBaseInUQ) {
        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            address asset = path[i + 1];
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).lastAssetPerBaseInUQ(asset),
                FixedPoint112.Q112
            );
            if (_asset == asset) {
                break;
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapV2PathPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}
