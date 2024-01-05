//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

interface IAirdrop {
    function setMerkleSet(bytes32 _root) external;
    function deposit(uint256 amount) external;
    function withdraw(bytes32[] calldata proof, uint256 amount) external;
    function bail() external;
}

