// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFeeDistributor {
    function is_killed() external view returns (bool);

    function start_time() external view returns (uint256);

    function time_cursor() external view returns (uint256);

    function last_token_time() external view returns (uint256);

    function time_cursor_of(address account) external view returns (uint256);

    function user_epoch_of(address account) external view returns (uint256);

    function tokens_per_week(uint256 week_cursor)
        external
        view
        returns (uint256);

    function ve_supply(uint256 week_cursor) external view returns (uint256);
}
