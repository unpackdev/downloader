// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IInsureGauge {
    function deposit(uint256 _value, address _addr) external;
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
    function template() external view returns(address);
}

interface IInsureVoteEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function smart_wallet_checker() external view returns (address);
}

interface IWalletChecker {
    function check(address) external view returns (bool);
}