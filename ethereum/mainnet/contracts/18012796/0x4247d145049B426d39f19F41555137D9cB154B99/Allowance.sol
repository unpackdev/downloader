//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./SafeTransferLib.sol";
import "./ERC20.sol";

library Allowance {
    using SafeTransferLib for ERC20;

    /**
     * @notice Approve the router/aggregator to spend the token if needed
     * @param _token address of the token to approve
     * @param _spender address of the router/aggregator
     */
    function _approveTokenIfNeeded(address _token, address _spender) internal {
        if (ERC20(_token).allowance(address(this), _spender) == 0) {
            ERC20(_token).safeApprove(_spender, type(uint256).max);
        }
    }
}
