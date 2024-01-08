// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IWETH.sol";

library DistributorLib {

    function transferOrCall(address to, uint256 amount) internal {
        // solhint-disable-next-line
        if (!payable(to).send(amount)) {
            // Calls with non empty calldata to trigger fallback()
            payable(to).call{value: amount} ("a"); 
        }
    }
}
