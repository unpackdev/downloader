// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./TraderJoeV21.sol";
import "./IBuyAdapter.sol";

/**
 * @dev This contract will route call to:
 * 1 - TraderJoeV21
 * The above are the indexes
 */
contract BuyAdapter02 is IBuyAdapter, TraderJoeV21 {
    using SafeMath for uint256;

    constructor(address _weth) public WethProvider(_weth) {}

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
            buyOnTraderJoeV21(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else {
            revert("Index not supported");
        }
    }
}
