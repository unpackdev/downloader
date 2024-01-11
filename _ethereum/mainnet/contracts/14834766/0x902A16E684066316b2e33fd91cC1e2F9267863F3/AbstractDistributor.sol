// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
import "./IERC20Upgradeable.sol";
import "./PreciseUnitMath.sol";
import "./SafeMathUpgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";

abstract contract AbstractDistributor {
    using SafeMathUpgradeable for uint256;
    event BuyCoverEvent(
        address _productAddress,
        uint256 _productId,
        uint256 _period,
        address _asset,
        uint256 _amount,
        uint256 _price
    );

    uint256 constant MAX_INT = type(uint256).max;

    uint256 constant DECIMALS18 = 10**18;

    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENTAGE_100 = 100 * PRECISION;

    address constant ETH = (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
}
