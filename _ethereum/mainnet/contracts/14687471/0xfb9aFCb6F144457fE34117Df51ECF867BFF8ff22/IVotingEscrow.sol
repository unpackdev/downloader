// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IVotingEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function token() external view returns (address);
    function locked() external view returns (uint256);
    function locked__end(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}