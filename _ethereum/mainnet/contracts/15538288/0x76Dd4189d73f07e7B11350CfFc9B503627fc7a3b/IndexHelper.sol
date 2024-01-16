// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./IERC20Metadata.sol";

import "./FixedPoint112.sol";
import "./FullMath.sol";

import "./IIndexHelper.sol";
import "./IIndex.sol";
import "./IvTokenFactory.sol";
import "./IvToken.sol";
import "./IIndexRegistry.sol";
import "./IPriceOracle.sol";

contract IndexHelper is IIndexHelper {
    using FullMath for uint;

    /// @inheritdoc IIndexHelper
    function totalEvaluation(address _index)
        external
        view
        override
        returns (uint _totalEvaluation, uint _indexPriceInBase)
    {
        IIndex index = IIndex(_index);
        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IIndexRegistry registry = IIndexRegistry(index.registry());
        IPriceOracle priceOracle = IPriceOracle(registry.priceOracle());

        (address[] memory assets, ) = index.anatomy();
        address[] memory inactiveAssets = index.inactiveAnatomy();

        for (uint i; i < assets.length + inactiveAssets.length; ++i) {
            address asset = i < assets.length ? assets[i] : inactiveAssets[i - assets.length];
            uint assetValue = IvToken(vTokenFactory.vTokenOf(asset)).assetBalanceOf(_index);
            _totalEvaluation += assetValue.mulDiv(FixedPoint112.Q112, priceOracle.lastAssetPerBaseInUQ(asset));
        }

        _indexPriceInBase = _totalEvaluation.mulDiv(
            10**IERC20Metadata(_index).decimals(),
            IERC20(_index).totalSupply()
        );
    }
}
