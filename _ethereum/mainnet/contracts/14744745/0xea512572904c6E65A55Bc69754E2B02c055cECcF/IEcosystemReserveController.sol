// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IEcosystemReserveController {
    function transfer(address collector, address token, address guy, uint256 wad) external;
}
