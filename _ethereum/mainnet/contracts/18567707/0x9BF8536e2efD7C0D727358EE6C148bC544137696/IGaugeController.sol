// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

interface IGaugeController {
    function admin() external view returns (address);

    function gauge_types(address addr) external view returns (int128);

    function gauge_relative_weight_write(address addr) external returns (uint256);

    function gauge_relative_weight_write(address addr, uint256 time) external returns (uint256);

    function gauge_relative_weight(address addr) external view returns (uint256);

    function gauge_relative_weight(address addr, uint256 time) external view returns (uint256);

    function add_gauge(address addr, int128 gauge_type) external;

    function add_gauge(address addr, int128 gauge_type, uint256 weight) external;

    function add_type(string memory _name, uint256 weight) external;

    function commit_transfer_ownership(address account) external;

    function accept_transfer_ownership() external;

    function n_gauges() external view returns (int128);

    function gauges(uint256 index) external view returns (address);

    function change_gauge_weight(address addr, uint256 weight) external;

    function get_gauge_weight(address addr) external view returns (uint256);

    function checkpoint() external;

    function checkpoint_gauge(address addr) external;

    function get_total_weight() external view returns (uint256);

    function time_total() external view returns (uint256);

    function points_total(uint256) external view returns (uint256);

    function vote_for_gauge_weights(address addr, uint256 weight) external;

    function vote_user_power(address addr) external returns (uint256);
}
