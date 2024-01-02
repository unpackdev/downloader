// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

// solhint-disable func-name-mixedcase

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function epoch() external view returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function apply_smart_wallet_checker() external;

    function apply_transfer_ownership() external;

    // function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function balanceOf(
        address user,
        uint256 timestamp
    ) external view returns (uint256);

    function balanceOfAt(
        address addr,
        uint256 _block
    ) external view returns (uint256);

    function checkpoint() external;

    function commit_smart_wallet_checker(address addr) external;

    function commit_transfer_ownership(address addr) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function decimals() external view returns (uint256);

    function deposit_for(address _addr, uint256 _value) external;

    function get_last_user_slope(address addr) external view returns (int128);

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function locked__end(address _addr) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupplyAtT(uint256 _timestamp) external view returns (uint256);

    function user_point_epoch(address user) external view returns (uint256);

    function user_point_history__ts(
        address _addr,
        uint256 _idx
    ) external view returns (uint256);

    function user_point_history(
        address user,
        uint256 timestamp
    ) external view returns (Point memory);
    function withdraw() external;


    // hack to access the mappings
    function slope_changes(uint _timestamp) external view returns (int128);

    // Access to the point_history mapping
    function point_history(uint _epoch) external view returns (Point memory);
}