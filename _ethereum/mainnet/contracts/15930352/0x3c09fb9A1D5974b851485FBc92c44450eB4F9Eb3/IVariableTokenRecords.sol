// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IVariableTokenRecords {
    function increaseBalance(
        address _tokenRecipient,
        uint256 _vaultType,
        uint256 _tokenAmount,
        bool _isFallback
    )
        external
    ;

    function clearBalance(address _tokenRecipient, uint256 _vaultType) external;

    function getAccountState(address _account, uint256 _vaultType)
        external
        view
        returns(uint256 balance, uint256 fallbackCount)
    ;
}

