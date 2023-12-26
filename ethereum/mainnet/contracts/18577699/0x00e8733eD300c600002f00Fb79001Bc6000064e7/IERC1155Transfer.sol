// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155Transfer {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}
