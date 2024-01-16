//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./BytesUtil.sol";

abstract contract ERC20BasicApproveExtension is ContextUpgradeable {

    /// @notice Temporarily approve `target` to spend `amount` and call it with data.
    /// Previous approvals remains unchanged.
    /// @param target The destination of the call, allowed to spend the amount specified
    /// @param amount The number of tokens allowed to spend.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function paidCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, _msgSender()), "FIRST_PARAM_NOT_SENDER");

        if (amount > 0) {
            _addAllowanceIfNeeded(_msgSender(), target, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));

        return returnData;
    }

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual;
}
