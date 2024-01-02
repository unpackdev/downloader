// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./NewUniswapV2.sol";
import "./UniswapV3.sol";
import "./ZeroxV4.sol";
import "./Balancer.sol";
import "./BalancerV2.sol";
import "./MakerPsm.sol";
import "./AugustusRFQ.sol";
import "./HashFlow.sol";
import "./Maverick.sol";
import "./SwaapV2.sol";
import "./PolygonMigrator.sol";
import "./IBuyAdapter.sol";

/**
 * @dev This contract will route call to:
 * 1 - UniswapV2Forks
 * 2 - UniswapV3
 * 3 - ZeroXV4
 * 4 - BalancerV1
 * 5 - MakerPsm
 * 6 - AugustusRFQ
 * 7 - HashFlow
 * 8 - Maverick
 * 9 - BalancerV2
 * 10 - SwaapV2
 * 11 - PolygonMigrator
 * The above are the indexes
 */
contract BuyAdapter is
    IBuyAdapter,
    NewUniswapV2,
    UniswapV3,
    ZeroxV4,
    Balancer,
    BalancerV2,
    MakerPsm,
    AugustusRFQ,
    HashFlow,
    Maverick,
    SwaapV2,
    PolygonMigrator
{
    using SafeMath for uint256;

    constructor(
        address _weth,
        address _dai,
        address _matic,
        address _pol
    ) public WethProvider(_weth) MakerPsm(_dai) PolygonMigrator(_matic, _pol) {}

    function initialize(bytes calldata data) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function buy(
        uint256 index,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) external payable override {
        if (index == 1) {
            buyOnUniswapFork(fromToken, toToken, maxFromAmount, toAmount, payload);
        } else if (index == 2) {
            buyOnUniswapV3(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 3) {
            buyOnZeroXv4(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 4) {
            buyOnBalancer(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 5) {
            buyOnMakerPsm(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 6) {
            buyOnAugustusRFQ(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 7) {
            buyOnHashFlow(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 8) {
            buyOnMaverick(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 9) {
            buyOnBalancerV2(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 10) {
            buyOnSwaapV2(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 11) {
            buyOnPolygonMigrator(fromToken, toToken, toAmount, targetExchange);
        } else {
            revert("Index not supported");
        }
    }
}
