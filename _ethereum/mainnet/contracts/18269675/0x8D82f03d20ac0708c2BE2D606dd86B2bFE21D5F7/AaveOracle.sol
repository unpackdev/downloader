//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./Math.sol";

import "./IAaveOracle.sol";
import "./IPoolAddressesProvider.sol";

import "./Arrays.sol";
import "./IOracle.sol";

contract AaveOracle is IOracle {

    using Math for *;

    IPoolAddressesProvider public immutable provider;

    constructor(IPoolAddressesProvider _provider) {
        provider = _provider;
    }

    function rate(IERC20 base, IERC20 quote) external view override returns (uint256) {
        uint256[] memory pricesArr = IAaveOracle(provider.getPriceOracle()).getAssetsPrices(toArray(address(base), address(quote)));
        return pricesArr[0].mulDiv(10 ** quote.decimals(), pricesArr[1]);
    }

}
