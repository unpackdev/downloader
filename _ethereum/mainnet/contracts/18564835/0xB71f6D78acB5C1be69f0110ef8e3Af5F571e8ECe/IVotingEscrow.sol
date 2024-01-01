// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVotingEscrow {
    struct LockedBalance {
        int128 amount; //weightedAmount
        uint256 amountA;
        uint256 amountB;
        uint256 amountC;
        uint256 end;
    }

    function create_lock(uint256, uint256, uint256, uint256) external;

    function increase_amount(uint256, uint256, uint256) external;

    function add_to_whitelist(address) external;

    function withdraw() external;

    function MINTIME() external view returns (uint256);

    function locked(address) external view returns (LockedBalance memory);

    function unlocked() external view returns (bool);
}
