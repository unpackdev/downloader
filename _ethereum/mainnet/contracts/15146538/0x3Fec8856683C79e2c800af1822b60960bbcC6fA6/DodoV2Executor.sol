// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";


interface IDODOV2 {
    function sellBase(address recipient)
        external
        returns (uint256);

    function sellQuote(address recipient)
        external
        returns (uint256);
}

abstract contract DodoV2Executor {
    using SafeERC20 for IERC20;

    function swapDodoV2(
        uint256 sellAmount,
        IDODOV2 pool,
        address recipient,
        IERC20 sourceToken,
        bool isSellBase
    ) external {
        // Transfer the tokens into the pool
        sourceToken.safeTransfer(address(pool), sellAmount);

        if (isSellBase) {
            pool.sellBase(recipient);
        } else {
            pool.sellQuote(recipient);
        }
    }
}
