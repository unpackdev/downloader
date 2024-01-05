// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAlchemist {
    function mintGold(address _to, uint256 _amount) external returns (bool);
}
