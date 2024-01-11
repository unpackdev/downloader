//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IIdleCDO {
    function depositAA(uint256 _amount) external returns (uint256);

    function depositBB(uint256 _amount) external returns (uint256);
}
