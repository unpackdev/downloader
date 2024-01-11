//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IKillswitch {
    function isEnabled() external view returns (bool);
    function enableContract() external;
    function disableContract() external;
}
