// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGaugeController {
    function gauge_types(address _addr)external view returns(uint256);
    function get_voting_escrow()external view returns(address);
    function checkpoint_gauge(address addr)external;
    function gauge_relative_weight(address addr, uint256 time)external view returns(uint256);
}