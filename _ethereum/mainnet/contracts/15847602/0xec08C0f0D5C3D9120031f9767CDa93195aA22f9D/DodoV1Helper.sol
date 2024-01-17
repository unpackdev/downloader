// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./DodoV1.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title DodoV1Helper
 * @notice Helper that performs onchain calculation required to call a Dodo v1 contract and returns corresponding caller and data
 */
abstract contract DodoV1Helper {
    using SafeERC20 for IERC20;

    function swapQuoteTokenDodoV1(
        uint256 sellAmount,
        IDODO pool,
        IDODOHelper helper
    ) external view returns (address target, bytes memory data) {
        uint256 boughtAmount = helper.querySellQuoteToken(pool, sellAmount);
        bytes memory resultData = abi.encodeWithSelector(pool.buyBaseToken.selector, boughtAmount, sellAmount, "");
        return (address(pool), resultData);
    }
}
