// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Address.sol";
import "./IWETH.sol";

abstract contract SafeTransfer {
    // The following song-and-dance is needed to avoid a DoS attack.
    // Read more: https://medium.com/northwest-nfts/how-to-safely-push-payments-in-smart-contracts-nouns-dao-and-ethernauts-king-challenge-584feca283d4
    function safeTransferETH(
        address wethAddress,
        address to,
        uint256 amount
    ) internal {
        require(wethAddress != address(0), "Creator: wethAddress not set");

        if (amount == 0) {
            return;
        }

        (bool success, ) = to.call{value: amount, gas: 30000}(new bytes(0));
        if (success) {
            return;
        }

        IWETH(wethAddress).deposit{value: amount}();
        IERC20(wethAddress).transfer(to, amount);
    }
}
