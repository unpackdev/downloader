// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface IVault {
    function asset() external view returns (address);

    function variableToken() external view returns (address);

    function requestAsset(uint256 _amount, address _to, bool _forVariableToken) external returns (address assetAddress);
}
