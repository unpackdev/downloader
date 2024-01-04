// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectCompound.sol";

function _encodeDepositCompound(
    address _token,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectCompound.deposit.selector,
            _token,
            _amt,
            _getId,
            _setId
        );
}

function _encodeBorrowCompound(
    address _token,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectCompound.borrow.selector,
            _token,
            _amt,
            _getId,
            _setId
        );
}
