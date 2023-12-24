// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IDsrManager {
    function pot() external view returns (address);

    function pieOf(address usr) external view returns(uint256);

    function daiBalance(address usr) external returns (uint256 wad);

    function join(address dst, uint256 wad) external;

    function exit(address dst, uint256 wad) external;

    function exitAll(address dst) external;
}
