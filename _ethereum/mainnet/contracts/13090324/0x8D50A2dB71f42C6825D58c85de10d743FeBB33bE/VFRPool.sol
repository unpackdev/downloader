// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VPoolBase.sol";

// solhint-disable no-empty-blocks
contract VFRPool is VPoolBase {
    address public buffer;

    event BufferSet(address buffer);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) VPoolBase(_name, _symbol, _token) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _token,
        address _poolAccountant,
        address _addressListFactory
    ) public initializer {
        _initializeBase(_name, _symbol, _token, _poolAccountant, _addressListFactory);
    }

    function setBuffer(address _buffer) external onlyGovernor {
        require(_buffer != address(0), "buffer-address-is-zero");
        require(_buffer != buffer, "same-buffer-address");
        buffer = _buffer;
        emit BufferSet(_buffer);
    }
}
