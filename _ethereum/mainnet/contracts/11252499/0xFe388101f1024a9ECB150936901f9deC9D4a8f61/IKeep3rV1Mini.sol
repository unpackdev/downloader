//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
interface IKeep3rV1Mini {
    function isKeeper(address) external returns (bool);
    function worked(address keeper) external;
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
    function votes(address keeper) external view returns (uint);
    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool);
    function addCreditETH(address job) external payable;
    function workedETH(address keeper) external;
}