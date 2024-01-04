// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectBasic {
    function withdraw(
        address _erc20,
        uint256 _tokenAmt,
        address payable _to,
        uint256 _getId,
        uint256 _setId
    ) external payable;
}
