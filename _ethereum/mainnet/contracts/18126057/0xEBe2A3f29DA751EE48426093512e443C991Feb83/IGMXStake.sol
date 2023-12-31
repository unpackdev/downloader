pragma solidity ^0.6.10;

interface IGMXStake {
    function stakeGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;
}
