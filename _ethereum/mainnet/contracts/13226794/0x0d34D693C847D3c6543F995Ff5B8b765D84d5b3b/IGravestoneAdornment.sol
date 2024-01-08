// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IGravestoneAdornment {
    event Create(address indexed creator_, uint256 indexed adornmentId_);

    function create(bytes32[] calldata gravestoneAdornment_)
        external
        returns (uint256);

    function valid(uint256 adornmentId_) external view returns (bool);

    function gravestoneAdornment(uint256 adornmentId_)
        external
        view
        returns (bytes32[] memory);
}
