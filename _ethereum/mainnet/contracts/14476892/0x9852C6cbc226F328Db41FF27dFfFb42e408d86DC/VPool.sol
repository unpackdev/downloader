// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VPoolBase.sol";

//solhint-disable no-empty-blocks
contract VPool is VPoolBase {
    string public constant VERSION = "5.0.0";

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) VPoolBase(_name, _symbol, _token) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _token,
        address _poolAccountant
    ) public initializer {
        _initializeBase(_name, _symbol, _token, _poolAccountant);
    }
}
