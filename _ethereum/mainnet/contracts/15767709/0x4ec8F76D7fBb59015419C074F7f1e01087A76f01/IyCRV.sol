/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IyCRV {
    function mint(uint256 _amount, address _recipient)
        external
        payable
        returns (uint256);
}
