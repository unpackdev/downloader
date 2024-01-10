// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./RevertReasonParser.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

contract Permitable {
    event Error(string reason);

    function _permit(
        IERC20 token,
        uint256 amount,
        bytes calldata permit
    ) internal {
        if (permit.length == 32 * 7) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(token).call(
                abi.encodePacked(IERC20Permit.permit.selector, permit)
            );
            if (!success) {
                string memory reason = RevertReasonParser.parse(
                    result,
                    "Permit call failed: "
                );
                if (token.allowance(msg.sender, address(this)) < amount) {
                    revert(reason);
                } else {
                    emit Error(reason);
                }
            }
        }
    }
}
