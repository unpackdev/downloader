// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IConnectMaker.sol";

function _encodeOpenMakerVault(string memory _colType)
    pure
    returns (bytes memory)
{
    return abi.encodeWithSelector(IConnectMaker.open.selector, _colType);
}

function _encodeBorrowMakerVault(
    uint256 _vaultId,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectMaker.borrow.selector,
            _vaultId,
            _amt,
            _getId,
            _setId
        );
}

function _encodedDepositMakerVault(
    uint256 _vaultId,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectMaker.deposit.selector,
            _vaultId,
            _amt,
            _getId,
            _setId
        );
}

function _encodePaybackMakerVault(
    uint256 _vaultId,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectMaker.payback.selector,
            _vaultId,
            _amt,
            _getId,
            _setId
        );
}

function _encodedWithdrawMakerVault(
    uint256 _vaultId,
    uint256 _amt,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectMaker.withdraw.selector,
            _vaultId,
            _amt,
            _getId,
            _setId
        );
}
