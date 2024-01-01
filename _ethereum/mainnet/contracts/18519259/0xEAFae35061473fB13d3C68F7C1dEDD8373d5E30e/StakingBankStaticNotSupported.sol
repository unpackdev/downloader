// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IStakingBank.sol";

abstract contract StakingBankStaticNotSupported is IStakingBank {
    error NotSupported();

    function create(address, string calldata) external pure {
        revert NotSupported();
    }

    function update(address, string calldata) external pure {
        revert NotSupported();
    }

    function remove(address) external pure {
        revert NotSupported();
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function receiveApproval(address) external pure returns (bool) {
        revert NotSupported();
    }

    function allowance(address, address) external pure returns (uint256) {
        revert NotSupported();
    }

    function approve(address, uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function stake(uint256) external pure {
        revert NotSupported();
    }

    function withdraw(uint256) external pure returns (bool) {
        revert NotSupported();
    }

    function exit() external pure returns (bool) {
        revert NotSupported();
    }

    function setMinAmountForStake(uint256) external pure {
        revert NotSupported();
    }
}
