// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ICallExecutor.sol";


interface ICallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    )
        external
        payable
    ;

    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executor() external view returns (ICallExecutor);

    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    )
        external
        view
        returns (uint256)
    ;

    function executionBudget(address _account) external view returns (uint256);
}
