// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategy {
    event AddressUpdated(string _type, address old, address _new);
    function paused() external returns (bool);
    function core() external returns (address);
    function treasury() external returns (address);
    function totalDeposits(address _token) external returns (uint256);
    
    // core only
    function invest(address _token, uint256 _amount) external;
    function divest(address _token, uint256 _amount) external;

    // admin only
    function collect(address _token) external;
    function setCore(address _core) external;
    function setTreasury(address _treasury) external;
    function setPaused(bool _paused) external;
}