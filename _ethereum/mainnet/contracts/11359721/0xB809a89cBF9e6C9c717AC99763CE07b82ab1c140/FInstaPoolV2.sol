// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IConnectInstaPoolV2.sol";

function _encodeFlashPayback(
    address _token,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectInstaPoolV2.flashPayback.selector,
            _token,
            _amt,
            _getId,
            _setId
        );
}
