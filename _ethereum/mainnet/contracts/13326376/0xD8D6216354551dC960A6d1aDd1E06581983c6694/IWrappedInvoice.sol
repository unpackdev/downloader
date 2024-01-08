// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedInvoice {
    function init(
        address _parent,
        address _child,
        address _invoice,
        uint256 _splitFactor
    ) external;

    function withdrawAll() external;

    function withdrawAll(address _token) external;

    function withdraw(uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees
    ) external;

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token
    ) external;

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        uint256 _amount
    ) external;

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token,
        uint256 _amount
    ) external;

    function lock(bytes32 _details) external payable;
}
