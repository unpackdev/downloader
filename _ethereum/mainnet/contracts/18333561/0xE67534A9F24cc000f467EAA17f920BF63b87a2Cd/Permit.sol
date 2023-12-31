// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SignatureUtil.sol";
import "./draft-IERC20Permit.sol";
import "./IERC20.sol";

library Permit {
    using SignatureUtil for bytes;

    function executePermit(address _tokenAddress, bytes memory _permitEnvelope) internal {
        if (_permitEnvelope.length > 0) {
            uint256 permitAmount = _permitEnvelope.toUint256(0);
            uint256 deadline = _permitEnvelope.toUint256(32);
            (bytes32 r, bytes32 s, uint8 v) = _permitEnvelope.parseSignature(64);
            try
                IERC20Permit(_tokenAddress).permit(
                    msg.sender,
                    address(this),
                    permitAmount,
                    deadline,
                    v,
                    r,
                    s
                )
            {
                return;
            } catch {
                if (IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= permitAmount) {
                    return;
                }
            }
            revert("Permit failure");
        }
    }
}
