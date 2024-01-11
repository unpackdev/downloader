// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IMoonshotMechanism {
    function getGoal() external view returns(uint);
    function getMoonshotBalance() external view returns(uint);
    function launchMoonshot() external;
    function shouldLaunchMoon(address from, address to) external view returns (bool);
}
