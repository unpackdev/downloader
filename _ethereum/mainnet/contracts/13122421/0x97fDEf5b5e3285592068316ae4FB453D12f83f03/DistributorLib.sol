// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IWETH.sol";

library DistributorLib {
    IWETH internal constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /**
     * @dev Attempt to transfer ETH, if failed wrap the ETH and send WETH. So that the
     * transfer always succeeds
     * @param to: The address to send ETH to
     * @param amount: The amount to send
     */
    function transferOrWrapETH(address to, uint256 amount) internal {
        // solhint-disable-next-line
        if (!payable(to).send(amount)) {
            WETH.deposit{value: amount}();
            WETH.transfer(to, amount);
        }
    }
}
