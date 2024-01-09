// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPolls.sol";

interface IEcliptic {
    function polls() external returns (IPolls);
    function transferPoint(uint32, address, bool) external;
    function setVotingProxy(uint8, address) external;
    function setManagementProxy(uint32, address) external;
}
