// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library GelatoCallUtils {
    function safeExternalCall(
        address _dest,
        bytes calldata _data,
        uint256 _gas
    ) internal {
        require(
            _dest.code.length > 0,
            "GelatoCallUtils.safeExternalCall: _dest cannot be EOA"
        );

        (bool success, ) = _dest.call{gas: _gas}(_data);
        require(
            success,
            "GelatoCallUtils.safeExternalCall: External call failed"
        );
    }
}
