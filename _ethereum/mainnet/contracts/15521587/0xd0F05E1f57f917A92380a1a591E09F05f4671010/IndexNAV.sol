// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./IERC20.sol";

import "./FixedPoint112.sol";
import "./FullMath.sol";

import "./IIndex.sol";
import "./IvTokenFactory.sol";
import "./IvToken.sol";
import "./IIndexRegistry.sol";
import "./IPriceOracle.sol";

contract IndexNAV {
    using FullMath for uint;

    function getNAV(address _index) external view returns (uint _nav, uint _totalSupply) {
        IIndex index = IIndex(_index);
        _totalSupply = IERC20(_index).totalSupply();
        (address[] memory assets, ) = index.anatomy();
        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IIndexRegistry registry = IIndexRegistry(index.registry());
        IPriceOracle priceOracle = IPriceOracle(registry.priceOracle());
        for (uint i; i < assets.length; ++i) {
            uint assetValue = IvToken(vTokenFactory.vTokenOf(assets[i])).assetBalanceOf(_index);
            _nav += assetValue.mulDiv(FixedPoint112.Q112, priceOracle.lastAssetPerBaseInUQ(assets[i]));
        }
    }
}
